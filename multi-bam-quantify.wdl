import "expression-quantification/quantify-from-bam.wdl" as quantify
import "tasks/mergecounts.wdl" as mergeCounts

workflow MultiBamExpressionQuantification {
    Array[Pair[String,File]]+ bams
    String outputDir
    String strandedness
    File ref_gtf
    File ref_refflat

    scatter (bam in bams) {
        call quantify.QuantifyFromBam as expressionQuantifications {
            input:
                inputBam = bam.right,
                referenceGtf = ref_gtf,
                referenceRefFlat = ref_refflat,
                sample = bam.left,
                strandedness = strandedness,
                outputDir = outputDir
        }
    }

    # Merge count tables into one multisample count table per count type
    call mergeCounts.MergeCounts as mergedTPMs {
        input:
            inputFiles = expressionQuantifications.TPMTable,
            outputFile = outputDir + "/TPM/all_samples.TPM",
            idVar = "'Gene ID'",
            measurementVar = "TPM"
    }

    call mergeCounts.MergeCounts as mergedFPKMs {
        input:
            inputFiles = expressionQuantifications.FPKMTable,
            outputFile = outputDir + "/FPKM/all_samples.FPKM",
            idVar = "'Gene ID'",
            measurementVar = "FPKM"
    }

    call mergeCounts.MergeCounts as mergedFragmentsPerGenes {
        input:
            inputFiles = expressionQuantifications.fragmentsPerGeneTable,
             outputFile = outputDir + "/fragments_per_gene/all_samples.fragments_per_gene",
            idVar = "feature",
            measurementVar = "counts"
    }

    call mergeCounts.MergeCounts as mergedBaseCountsPerGene {
        input:
            inputFiles = expressionQuantifications.baseCountsPerGeneTable,
            outputFile = outputDir + "/all_samples.base.gene.counts",
            idVar = "X1",
            measurementVar = "X2"
    }

    output {
        File baseCountsPerGeneTable = mergedBaseCountsPerGene.mergedCounts
        File fragmentsPerGeneTable = mergedFragmentsPerGenes.mergedCounts
        File FPKMTable = mergedFPKMs.mergedCounts
        File TPMTable = mergedTPMs.mergedCounts

    }
}