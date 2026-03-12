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

  <!-- ================================================================== -->
  <!-- Obtain constants and TEI-header-document node -->
  <!-- ================================================================== -->

  <!-- Get constants from input filename -->
  <xsl:variable name="input-filename" select="tokenize(document-uri(/), '/')[last()]"/>
  <xsl:variable name="krp-number"
                select="lower-case(replace($input-filename, '.*?(KRP-\d{3}).*', '$1'))"/>
  <xsl:variable name="header-path"
                select="concat('../../templates/', $krp-number, '.xml')"/>

  <!-- Load and parse header doc, return document node; otherwise fail -->
  <xsl:variable name="header-doc" select="document($header-path)"/>

  <!-- ================================================================== -->
  <!-- Assemble processing instructions from TEI-header document -->
  <!-- ================================================================== -->

  <xsl:template match="/">
    <!-- Copy processing instructions from header doc -->
    <xsl:copy-of select="$header-doc/processing-instruction()"/>
    <!-- Insert newline -->
    <xsl:text>&#10;</xsl:text>
    <xsl:apply-templates select="tei:TEI"/>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- Merge TEI header from TEI-header document with input text -->
  <!-- ================================================================== -->

  <xsl:template match="tei:TEI">
    <!-- Save reference to input's text element before xsl:copy changes context -->
    <xsl:variable name="input-text" select="tei:text"/>
    <!-- Create root element from header doc -->
    <xsl:copy select="$header-doc/tei:TEI">
      <!-- Copy full root-element attributes from header doc -->
      <xsl:copy-of select="$header-doc/tei:TEI/@*"/>
      <!-- Copy full TEI header from header doc;
           note: schema-aware Saxon-PE processing will expand TEI schema
           default attributes into the XML output - this is expected and accepted -->
      <xsl:copy-of select="$header-doc/tei:TEI/tei:teiHeader"/>
      <!-- Apply upconversion to text element in input doc (converted from DOCX with TEIGarage) -->
      <xsl:apply-templates select="$input-text"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
