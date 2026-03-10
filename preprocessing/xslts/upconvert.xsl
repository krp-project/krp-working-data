<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                version="3.0">

  <xsl:output method="xml" indent="yes"
              xmlns:saxon="http://saxon.sf.net/"
              saxon:indent-spaces="4"/>

  <!-- Identity transform: copy everything as-is -->
  <xsl:mode on-no-match="shallow-copy"/>

  <!-- Rename output file: replace _RL_DS_IS_AHform with _body -->
  <xsl:template match="/">
    <xsl:variable name="input-filename" select="tokenize(document-uri(/), '/')[last()]"/>
    <xsl:variable name="output-filename" select="replace($input-filename, '_RL_DS_IS_AHform', '_body')"/>
    <xsl:result-document href="{$output-filename}">
      <xsl:apply-templates/>
    </xsl:result-document>
  </xsl:template>

</xsl:stylesheet>
