import "tasks/stringtie.wdl" as stringtie_task

workflow QuantifyStringtie {
    File bamFile
    String outputDir
    String sample
    String countType

    call stringtie_task.Stringtie as stringtie {
        input:
            alignedReads = bamFile,
            assembledTranscriptsFile = outputDir + "/" + sample + ".gff",
            geneAbundanceFile = outputDir + "/" + sample + ".abundance"
    }


    call FetchCounts as fetchCounts {
        input:
            abundanceFile = stringtie.geneAbundance,
            outputFile = outputDir + "/" + sample + "." + countType,
            column = if countType == "TPM" then 9 else 8
    }

    output{
        File counts = fetchCounts.counts
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