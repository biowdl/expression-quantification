version 1.0

# Copyright (c) 2018 Leiden University Medical Center
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import "tasks/collect-columns.wdl" as collectColumns
import "tasks/common.wdl" as common
import "tasks/htseq.wdl" as htseq
import "tasks/stringtie.wdl" as stringtie_task
import "tasks/samtools.wdl" as samtools

workflow MultiBamExpressionQuantification {
    input {
        Array[Pair[String,IndexedBamFile]]+ bams #(sample, (bam, index))
        String outputDir = "."
        String strandedness
        File? referenceGtfFile # Not providing the reference gtf will have stringtie do an unguided assembly
        Boolean detectNovelTranscripts = if defined(referenceGtfFile) then false else true
        Array[String]+? additionalAttributes

        Map[String, String] dockerImages = {
            "htseq": "quay.io/biocontainers/htseq:0.12.4--py37hb3f55d8_0",
            "stringtie": "quay.io/biocontainers/stringtie:2.1.2--h7e0af3c_1",
            "collect-columns": "quay.io/biocontainers/collect-columns:0.2.0--py_1",
            "samtools": "quay.io/biocontainers/samtools:1.8--h46bd0b3_5"
        }
    }
    meta {allowNestedInputs: true}

    String stringtieDir = outputDir + "/stringtie/"
    String stringtieAssemblyDir = outputDir + "/stringtie/assembly/"
    String htSeqDir = outputDir + "/fragments_per_gene/"

    if (detectNovelTranscripts) {
        # assembly per sample
        scatter (sampleBam in bams) {
            IndexedBamFile bamFileAssembly = sampleBam.right
            String sampleIdAssembly = sampleBam.left

            call stringtie_task.Stringtie as stringtieAssembly {
                input:
                    bam = bamFileAssembly.file,
                    bamIndex = bamFileAssembly.index,
                    assembledTranscriptsFile = stringtieAssemblyDir + sampleIdAssembly + ".gtf",
                    firstStranded = if strandedness == "RF" then true else false,
                    secondStranded = if strandedness == "FR" then true else false,
                    referenceGtf = referenceGtfFile,
                    skipNovelTranscripts = false,
                    dockerImage = dockerImages["stringtie"]
            }
        }

        # merge assemblies
        call stringtie_task.Merge as mergeStringtieGtf {
            input:
                gtfFiles = stringtieAssembly.assembledTranscripts,
                outputGtfPath = stringtieAssemblyDir + "/merged.gtf",
                guideGtf = referenceGtfFile,
                dockerImage = dockerImages["stringtie"]
        }
    }

    # call counters per sample, using merged assembly if generated
    scatter (sampleBam in bams) {
        IndexedBamFile bamFile = sampleBam.right
        String sampleId = sampleBam.left

        call stringtie_task.Stringtie as stringtie {
            input:
                bam = bamFile.file,
                bamIndex = bamFile.index,
                assembledTranscriptsFile = stringtieDir + sampleId + ".gtf",
                geneAbundanceFile = stringtieDir + sampleId + ".abundance",
                firstStranded = if strandedness == "RF" then true else false,
                secondStranded = if strandedness == "FR" then true else false,
                referenceGtf = select_first([mergeStringtieGtf.mergedGtfFile, referenceGtfFile]),
                skipNovelTranscripts = true,
                dockerImage = dockerImages["stringtie"]
        }

        call samtools.SortByName as samtoolsSort {
            input:
                bamFile = bamFile.file,
                dockerImage = dockerImages["samtools"]
        }

        Map[String, String] HTSeqStrandOptions = {"FR": "yes", "RF": "reverse", "None": "no"}
        call htseq.HTSeqCount as htSeqCount {
            input:
                inputBams = [samtoolsSort.outputBam],
                outputTable = htSeqDir + sampleId + ".fragments_per_gene",
                stranded = HTSeqStrandOptions[strandedness],
                # Use the reference gtf if provided. Otherwise use the gtf file generated by stringtie
                gtfFile = select_first([mergeStringtieGtf.mergedGtfFile, referenceGtfFile]),
                order = "name",
                dockerImage = dockerImages["htseq"]
        }
    }

    # Merge count tables into one multisample count table per count type
    call collectColumns.CollectColumns as mergedStringtieTPMs {
        input:
            inputTables = select_all(stringtie.geneAbundance),
            outputPath = stringtieDir + "/all_samples.TPM",
            valueColumn = 8,
            sampleNames = sampleId,
            header = true,
            additionalAttributes = additionalAttributes,
            referenceGtf = select_first([mergeStringtieGtf.mergedGtfFile, referenceGtfFile]),
            dockerImage = dockerImages["collect-columns"]
    }

    call collectColumns.CollectColumns as mergedStringtieFPKMs {
        input:
            inputTables = select_all(stringtie.geneAbundance),
            outputPath = stringtieDir + "/all_samples.FPKM",
            valueColumn = 7,
            sampleNames = sampleId,
            header = true,
            additionalAttributes = additionalAttributes,
            referenceGtf = select_first([mergeStringtieGtf.mergedGtfFile, referenceGtfFile]),
            dockerImage = dockerImages["collect-columns"]
    }

    call collectColumns.CollectColumns as mergedHTSeqFragmentsPerGenes {
        input:
            inputTables = htSeqCount.counts,
            outputPath = htSeqDir + "/all_samples.fragments_per_gene",
            sampleNames = sampleId,
            additionalAttributes = additionalAttributes,
            referenceGtf = select_first([mergeStringtieGtf.mergedGtfFile, referenceGtfFile]),
            dockerImage = dockerImages["collect-columns"]
    }

    output {
        File fragmentsPerGeneTable = mergedHTSeqFragmentsPerGenes.outputTable
        Array[File] sampleFragmentsPerGeneTables = htSeqCount.counts
        File FPKMTable = mergedStringtieFPKMs.outputTable
        File TPMTable = mergedStringtieTPMs.outputTable

        Array[Pair[String, File]] sampleGtfFiles = if detectNovelTranscripts
            then zip(select_first([sampleIdAssembly]),
                select_first([stringtieAssembly.assembledTranscripts]))
            else []
        File? mergedGtfFile = mergeStringtieGtf.mergedGtfFile
    }

    parameter_meta {
        bams: {description: "A list of pairs in which the left item is a sample Id and the right item an object containing the paths to that samples BAM file and its index.",
               category: "required"}
        outputDir: {description: "The directory to which the outputs will be written.", category: "common"}
        strandedness: {description: "The strandedness of the RNA sequencing library preparation. One of \"None\" (unstranded), \"FR\" (forward-reverse: first read equal transcript) or \"RF\" (reverse-forward: second read equals transcript).",
                       category: "required"}
        referenceGtfFile: {description: "A reference GTF file. If detectNovelTranscripts is set to true then this reference GTF will be used as a guide during transcript assembly, otherwise this GTF file is used directly as the annotation source for read counting. If undefined `detectNovelTranscripts` will be set to true by default.",
                           category: "common"}
        detectNovelTranscripts: {description: "Whether or not a transcripts assembly should be used. If set to true Stringtie will be used to create a new GTF file based on the BAM files. This generated GTF file will be used for expression quantification. If `referenceGtfFile` is also provided this reference GTF will be used to guide the assembly.",
                                 category: "common"}
        additionalAttributes: {description: "Additional attributes which should be taken from the GTF used for quantification and added to the merged expression value tables.",
                               category: "advanced"}
        dockerImages: {description: "The docker images used. Changing this may result in errors which the developers may choose not to address.",
                       category: "advanced"}
    }
}
