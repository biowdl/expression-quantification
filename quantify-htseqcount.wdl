# This workflow seems a bit redundant, since it only calls the HTSeqCount task.
# It is included to keep the same structure as with the others.

import "tasks/htseq.wdl" as htseq

workflow QuantifyHTSeqCount {
    Array[File] bamFiles
    String outputDir
    String sample

    call htseq.HTSeqCount as htSeqCount {
        input:
            alignmentFiles = bamFiles,
            outputTable = outputDir + "/" + sample + ".fragments_per_gene"
    }

    output {
        File counts = htSeqCount.counts
    }
}