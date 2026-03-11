<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xmlns:saxon="http://saxon.sf.net/"
                version="3.0">

  <!-- Saxon-specific indent specification -->
  <xsl:output method="xml" indent="yes"
              saxon:indent-spaces="4"/>

  <!-- Identity transform: recursively copy as-is by default; requires XSLT 3.0 -->
  <xsl:mode on-no-match="shallow-copy"/>

  <!-- Get constants from input filename -->
  <xsl:variable name="input-filename" select="tokenize(document-uri(/), '/')[last()]"/>
  <xsl:variable name="krp-number"
                select="lower-case(replace($input-filename, '.*?(KRP-\d{3}).*', '$1'))"/>
  <xsl:variable name="template-path"
                select="concat('../../templates/', $krp-number, '.xml')"/>
  <xsl:variable name="output-filename"
                select="replace($input-filename, '_RL_DS_IS_AHform', '_body')"/>

  <!-- Load and parse template doc, return document node; otherwise fail -->
  <xsl:variable name="template-doc" select="document($template-path)"/>

  <xsl:template match="/">
    <!-- Write result in specifically created output file -->
    <xsl:result-document href="{$output-filename}">
      <!-- Copy processing instructions from template -->
      <xsl:copy-of select="$template-doc/processing-instruction()"/>
      <!-- Insert newline -->
      <xsl:text>&#10;</xsl:text>
      <xsl:apply-templates select="tei:TEI"/>
    </xsl:result-document>
  </xsl:template>

  <!-- Merge template's TEI root element and teiHeader with input's text -->
  <xsl:template match="tei:TEI">
    <!-- Save reference to input's text before xsl:copy changes context -->
    <xsl:variable name="input-text" select="tei:text"/>
    <!-- Create root element from template doc -->
    <xsl:copy select="$template-doc/tei:TEI">
      <!-- Copy full root-element attributes from template doc -->
      <xsl:copy-of select="$template-doc/tei:TEI/@*"/>
      <!-- Copy full TEI header from template doc;
           note: schema-aware Saxon-PE processing will expand TEI schema
           default attributes into the XML output - this is expected and accepted -->
      <xsl:copy-of select="$template-doc/tei:TEI/tei:teiHeader"/>
      <!-- Apply upconversion to text element in input doc (converted from DOCX with TEIGarage) -->
      <xsl:apply-templates select="$input-text"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
