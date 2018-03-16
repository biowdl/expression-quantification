import "tasks/biopet.wdl" as biopet

workflow QuantifyBaseCounter {
    File bamFile
    String outputDir
    String sample
    String stranded

    call biopet.BaseCounter as baseCounter {
        input:
            bam = bamFile,
            outputDir = outputDir,
            prefix = sample
    }

    output {
        File counts =
            if stranded == "yes" then baseCounter.geneSense
            else (
                if stranded == "reverse" then baseCounter.geneAntisense
                else baseCounter.gene
            )
    }
}