---
layout: default
title: Home
version: develop
latest: true
---

This repository contains the [BioWDL](https://github.com/biowdl)
workflows usable for quantifying transcriptional expression measures.
There is currently one pipeline available: `multi-bam-quantify`,
which uses [HTSeq-Count](http://htseq.readthedocs.io/en/master/count.html),
[StringTie](https://ccb.jhu.edu/software/stringtie/) and
[BaseCounter](https://biopet.github.io/basecounter/index.html) to
determine various expression measures.

## Usage
`multi-bam-quantify` can be run using
[Cromwell](http://cromwell.readthedocs.io/en/stable/):

```
java -jar cromwell-<version>.jar run -i inputs.json multi-bam-quantify.wdl
```

The inputs JSON can be generated using WOMtools as described in the [WOMtools
documentation](http://cromwell.readthedocs.io/en/stable/WOMtool/).

The primary inputs are described below, additional inputs (such as precommands
and JAR paths) are available. Please use the above mentioned WOMtools command
to see all available inputs.

| field | type | |
|-|-|-|
| strandedness | `String` |  Indicates the strandedness of the input data. This should be one of the following: `FR` (Forward, Reverse),`RF` (Reverse, Forward) or  `None`: (Unstranded) |
| refRefflat | `File` | A Refflat file containing the annotations which will be used for counting. |
| refGtf | `File` | A GTF file containing the annotations which will be used for counting.
| bams | `Array[Pair[String, Pair[File, File]]]+` | Input BAM files and their indexes. See below for more information |
| outputDir | `String` | The path to the directory in which the output will be placed. This directory will be created if it doesn't exist yet. |

BAM files need to be given as an Array. Each of the elements in this array
corresponds to one sample and is a Pair in which the left element is a
name/label of the sample and the right element is a Pair. This inner Pair
contains the BAM file (left element) and its index (right element).
An example of how to do this in JSON:
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
of file location (a string in JSON). Types ending in `?` indicate the input is
optional, types ending in `+` indicate they require at least one element.

## Output
The `multi-bam-quantify` workflow produces three directories:
- **BaseCounter**: Contains BaseCounter ouput. Includes a file called
`all_samples.base.gene.counts`, which contains the counts for all samples.
- **stringtie**: Contains the stringtie output. Includes two additional folder:
  - **FPKM**: Contains per sample FPKM counts, extracted from the stringtie
  abundance output. Also contains a file called `all_samples.FPKM`, which
  contains the FPKM values for all samples.
  - **TPM**: Contains per sample TPM counts, extracted from the stringtie
  abundance output. Also contains a file called `all_samples.TPM`, which
  contains the TPM values for all samples.
- **fragments_per_gene**: Contains the HTSeq-Count output. Also contains a file
called `all_samples.fragments_per_gene`, which contains the counts for all
samples.

## About
These workflows are part of [BioWDL](https://biowdl.github.io/)
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
