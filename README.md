# Expression-Quantification

This repository contains the [Biowdl](https://github.com/biowdl)
workflows usable for quantifying transcriptional expression measures.
There is currently one pipeline available: `multi-bam-quantify`,
which uses [HTSeq-Count](http://htseq.readthedocs.io/en/master/count.html),
[StringTie](https://ccb.jhu.edu/software/stringtie/) and
[BaseCounter](https://biopet.github.io/basecounter/index.html) to
determine various expression measures.

## Usage
`multi-bam-quantify` can be run using [Cromwell]
(http://cromwell.readthedocs.io/en/stable/):

```
java -jar cromwell-<version>.jar run -i inputs.json multi-bam-quantify.wdl
```

The inputs json can be generated using womtools as described in the [womtools
documentation](http://cromwell.readthedocs.io/en/stable/WOMtool/).

The inputs are described below:

| field | type | |
|-|-|-|
| strandedness | `String` |  Indicates the strandedness of the input data. This should be one of the following: `FR` (Foreward, Reverse),`RF` (Reverse, Foreward) or  `None`: (Unstranded) |
| refRefflat | `File` | A Refflat file containing the annotations which will be used for counting. |
| refGtf | `File` | A GTF file containing the annotations which will be used for counting.
| bams | `Array[Pair[String, Pair[File, File]]]+` | Input bam files and their indexes. See below for more information |
| outputDir | `String` | The path to the directory in which the output will be placed. This directory will be created if it doesn't exist yet. |
| mergedHTSeqFragmentsPerGenes.preCommand | `String?` | |
| baseCounter.memoryMultiplier | `Float?` | |
| htSeqCount.format | `String?` ||
| baseCounter.preCommand | `String?` | |
| htSeqCount.memory | `Int?` | |
| stringtie.threads | `Int?` | |
| baseCounter.memory | `Float?` | |
| htSeqCount.order | `String?` | |
| mergedBaseCountsPerGene.preCommand | `String?` | |
| mergedStringtieFPKMs.preCommand | `String?` | |
| mergedStringtieTPMs.preCommand | `String?` | |
| htSeqCount.preCommand | `String?` | |
| baseCounter.toolJar | `File?` | |
| stringtie.preCommand | `String?` | |


Bams need to be given as an Array. Each of the elements in this array
corresponds to one sample and is a Pair in which the left element is a
name/label of the sample and the right element is a Pair. This inner Pair
contains the bam file (left element) and its index (right element).
An example of how to do this in json:
```
[
  {
    "Left":"sample1",
    "Right":{
      "Left":"sample1.bam",
      "Right":"sample1.bai"
    }
  },
  {
    "Left":"sample2",
    "Right":{
      "Left":"sample2.bam",
      "Right":"sample2.bai"
    }
  }
]
```

>All inputs have to be preceded by with `MultiBamExpressionQuantification.`.
Type is indicated according to the WDL data types: `File` should be indicators
of file location (a string in json). Types ending in `?` indicate the input is
optional, types ending in `+` indicate they require at least one element.

## Output


## About
These workflows are part of [Biowdl](https://biowdl.github.io/)
developed by [the SASC team](http://sasc.lumc.nl/).

## Contact

<p>
  <!-- Obscure e-mail address for spammers -->
For any question related to Expression-Quantification, please use the
<a href='https://github.com/biowdl/expression-quantification/issues'>github issue tracker</a>
or contact
 <a href='http://sasc.lumc.nl/'>the SASC team</a> directly at: <a href='&#109;&#97;&#105;&#108;&#116;&#111;&#58;&#115;&#97;&#115;&#99;&#64;&#108;&#117;&#109;&#99;&#46;&#110;&#108;'>
&#115;&#97;&#115;&#99;&#64;&#108;&#117;&#109;&#99;&#46;&#110;&#108;</a>.
</p>
