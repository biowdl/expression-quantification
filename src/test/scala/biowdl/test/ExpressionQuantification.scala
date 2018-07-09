/*
 * Copyright (c) 2018 Biowdl
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package biowdl.test

import java.io.File

import nl.biopet.utils.biowdl.Pipeline
import nl.biopet.utils.biowdl.annotations.Annotation

trait ExpressionQuantification extends Pipeline with Annotation {

  def strandedness: String = "None"

  def bamFiles: Map[String, File]
  val bamInput: List[Map[String, Any]] = bamFiles.keys
    .map(sample => {
      val innerMap: Map[String, String] =
        Map(
          "Left" -> bamFiles.get(sample).map(_.getAbsolutePath).getOrElse(""),
          "Right" -> {
            // Determine the samples index
            val index1 = new File(
              bamFiles
                .getOrElse(sample, {
                  throw new IllegalArgumentException("Missing bam file")
                })
                .getAbsolutePath + ".bai")
            val index2 = new File(
              bamFiles
                .getOrElse(sample, {
                  throw new IllegalArgumentException("Missing bam file")
                })
                .getAbsolutePath
                .stripSuffix(".bam") + ".bai")
            (index1.exists(), index2.exists()) match {
              case (true, _) => index1.getAbsolutePath
              case (_, true) => index2.getAbsolutePath
              case _         => throw new IllegalStateException("No index found")
            }
          }
        )

      val sampleMap: Map[String, Any] =
        Map("Left" -> sample, "Right" -> innerMap)
      sampleMap
    })
    .toList

  override def inputs: Map[String, Any] =
    super.inputs ++
      Map(
        "MultiBamExpressionQuantification.outputDir" -> outputDir.getAbsolutePath,
        "MultiBamExpressionQuantification.strandedness" -> strandedness,
        "MultiBamExpressionQuantification.refGtf" -> referenceGtf.map(
          _.getAbsolutePath),
        "MultiBamExpressionQuantification.refRefflat" -> referenceRefflat.map(
          _.getAbsolutePath),
        "MultiBamExpressionQuantification.bams" -> bamInput
      )

  def startFile: File = new File("./multi-bam-quantify.wdl")
}
