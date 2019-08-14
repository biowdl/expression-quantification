---
layout: default
title: Home
version: develop
latest: false
---

This workflow can be used to perform expression quantification for multiple
BAM files. Expression levels will be determined for each BAM file/sample
and will be merged together into a single table including all samples.

Expression quantification will be performed using
[StringTie](https://ccb.jhu.edu/software/stringtie/) and
[HTSeq-Count](http://htseq.readthedocs.io/en/master/count.html).

This workflow is part of [BioWDL](https://biowdl.github.io/)
developed by the SASC team at [Leiden University Medical Center](https://www.lumc.nl/)
.

## Usage
This workflow can be run using
[Cromwell](http://cromwell.readthedocs.io/en/stable/):
```bash
java -jar cromwell-<version>.jar run -i inputs.json multi-bam-quantify.wdl
```

### Inputs
Inputs are provided through a JSON file. The minimally required inputs are
described below and a template containing all possible inputs can be generated
using Womtool as described in the
[WOMtool documentation](http://cromwell.readthedocs.io/en/stable/WOMtool/).
See [this page](/inputs.html) for some additional general notes and information
about pipeline inputs.

```json
{
  "MultiBamExpressionQuantification.bams": "A list of BAM files and sample identifiers (see 'BAM file input' below)",
  "MultiBamExpressionQuantification.strandedness": "The strandedness of the samples: FR (forward-reverse), RF (reverse-forward) or None",
  "MultiBamExpressionQuantification.outputDir": "The path to the output directory.",
  "MultiBamExpressionQuantification.referenceGtfFile": "The path to the annotations GTF file. If not specified, Stringtie will be run unguided and the GTF file it produces will be used for HTSeq-Count",
}
```

#### BAM file input
BAM files need to be given as a list with one item per sample. Each of the
items should be an object containing a `"Left"` element (the sample id) and a
`"Right"` element (the BAM file and its index) following the structure as shown
here:
```json
{
  "Left": "Sample identifier",
  "Right": {
    "file": "The path to the sample's BAM file",
    "index": "The path to the index for the sample's BAM file"
  }
}
```

#### Example
```json
{
  "MultiBamExpressionQuantification.bams": [
    {
      "Left": "s1",
      "Right": {
        "file": "/home/user/mapping/results/s1.bam",
        "index": "/home/user/mapping/results/s1.bai"
      }
    }, {
      "Left": "s2",
      "Right": {
        "file": "/home/user/mapping/results/s2.bam",
        "index": "/home/user/mapping/results/s2.bai"
      }
    }
  ],
  "MultiBamExpressionQuantification.strandedness": "FR",
  "MultiBamExpressionQuantification.outputDir": "/home/user/expression/results",
  "MultiBamExpressionQuantification.referenceGtfFile": "/home/user/genomes/human/features/ensembl87.gtf"
}
```

### Tool versions
Included in the repository is an `environment.yml` file. This file includes
all the tool version on which the workflow was tested. You can use conda and
this file to create an environment with all the correct tools.

### Output
The `multi-bam-quantify` workflow produces two directories:
- **stringtie**: Contains the Stringtie output. Includes two additional folder:
  - **FPKM**: Contains per sample FPKM counts, extracted from the Stringtie
    abundance output. Also contains a file called `all_samples.FPKM`, which
    contains the FPKM values for all samples.
  - **TPM**: Contains per sample TPM counts, extracted from the Stringtie
    abundance output. Also contains a file called `all_samples.TPM`, which
    contains the TPM values for all samples.
- **fragments_per_gene**: Contains the HTSeq-Count output. Also contains a file
  called `all_samples.fragments_per_gene`, which contains the counts for all
  samples.

## Contact
<p>
  <!-- Obscure e-mail address for spammers -->
For any question about running this workflow and feature requests, please use
the
<a href='https://github.com/biowdl/expression-quantification/issues'>github issue tracker</a>
or contact
the SASC team
 directly at: <a href='&#109;&#97;&#105;&#108;&#116;&#111;&#58;&#115;&#97;&#115;&#99;&#64;&#108;&#117;&#109;&#99;&#46;&#110;&#108;'>
&#115;&#97;&#115;&#99;&#64;&#108;&#117;&#109;&#99;&#46;&#110;&#108;</a>.
</p>
