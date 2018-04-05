import "tasks/stringtie.wdl" as stringtie_task
import "tasks/biopet.wdl" as biopet
import "tasks/htseq.wdl" as htseq

workflow QuantifyFromBam {
    File inputBam
    File referenceGtf
    File referenceRefFlat

    String sample
    String strandedness

    String outputDir

    call stringtie_task.Stringtie as stringtie {
        input:
            alignedReads = inputBam,
            assembledTranscriptsFile = outputDir + "/stringtie/" + sample + ".gff",
            geneAbundanceFile = outputDir + "/stringtie/" + sample + ".abundance",
            firstStranded = if strandedness == "FR" then true else false,
            secondStranded = if strandedness == "RF" then true else false,
            referenceGtf = referenceGtf
    }

    call FetchCounts as fetchCountsTPM {
        input:
            abundanceFile = stringtie.geneAbundance,
            outputFile = outputDir + "/TPM/" + sample + ".TPM",
            column = 9
    }

    call FetchCounts as fetchCountsFPKM {
        input:
            abundanceFile = stringtie.geneAbundance,
            outputFile = outputDir + "/FPKM/" + sample + ".FPKM",
            column = 8
    }

    Map[String, String] HTSeqStrandOptions = {"FR": "yes", "RF": "reverse", "None": "no"}
    call htseq.HTSeqCount as htSeqCount {
        input:
            alignmentFiles = inputBam,
            outputTable = outputDir + "/fragments_per_gene/" + sample + ".fragments_per_gene",
            stranded = HTSeqStrandOptions[strandedness],
            gtfFile = referenceGtf
    }

    call biopet.BaseCounter as baseCounter {
        input:
            bam = inputBam,
            outputDir = outputDir + "/BaseCounter/",
            prefix = sample,
            refFlat = referenceRefFlat
    }

    output {
        File TPMTable = fetchCountsTPM.counts
        File FPKMTable = fetchCountsFPKM.counts
        File fragmentsPerGeneTable = htSeqCount.counts
        File baseCountsPerGeneTable = if strandedness == "FR" then baseCounter.geneSense else (
            if strandedness == "RF" then baseCounter.geneAntisense else baseCounter.gene)
    }
}


task FetchCounts {
    File abundanceFile
    String outputFile
    Int column

    command <<<
        awk -F "\t" '{print $1 "\t" $${column}}' ${abundanceFile} > ${outputFile}
    >>>

    output {
        File counts = outputFile
    }
}