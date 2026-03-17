<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.tei-c.org/ns/1.0"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                version="3.0"
                exclude-result-prefixes="tei">

  <xsl:output method="xml" indent="yes"/>

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
  <!-- Kick off processing;
       assemble processing instructions from TEI-header document -->
  <!-- ================================================================== -->

  <xsl:template match="/">
    <!-- Copy processing instructions from header doc -->
    <xsl:copy-of select="$header-doc/processing-instruction()"/>
    <!-- Insert newline -->
    <xsl:text>&#10;</xsl:text>
    <xsl:apply-templates select="tei:TEI"/>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- Merge TEI header from TEI-header document with input text body -->
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

  <!-- ================================================================== -->
  <!-- Upconvert input XML's text body -->
  <!-- ================================================================== -->

  <!-- Suppress front element -->
  <xsl:template match="tei:front"/>

  <xsl:template match="tei:body">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <!-- Save body content before xsl:copy changes context -->
      <xsl:variable name="body-content" select="node()"/>
      <!-- Save front element before xsl:copy changes context -->
      <xsl:variable name="front" select="../tei:front"/>
      <!-- Wrap body content in outermost div from TEI-header document -->
      <xsl:copy select="$header-doc//tei:body/tei:div">
        <xsl:copy-of select="$header-doc//tei:body/tei:div/@*"/>
        <!-- ================================================================== -->
        <!-- 1. Transform input-XML's front titlePage into document head -->
        <!-- ================================================================== -->
        <head type="dokument">
          <title type="num">
            <xsl:value-of select="normalize-space($front//tei:titlePart[@type='Title'])"/>
          </title>
          <title type="descr">
            <xsl:value-of select="normalize-space($front//tei:titlePart[@type='Subtitle'])"/>
          </title>
        </head>
        <xsl:apply-templates select="$body-content"/>
      </xsl:copy>
    </xsl:copy>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- 2. Transform Dokumentkopf head into div[@type='dokumentkopf'] -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = 'Dokumentkopf']]">
    <div type="dokumentkopf">
      <xsl:apply-templates select="tei:div"/>
    </div>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- 3. Derive types of Dokumentkopf-divs from head -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = 'Dokumentkopf']]/tei:div">
    <xsl:variable name="type-value"
                  select="lower-case(replace(normalize-space(tei:head), ':\s*$', ''))"/>
    <div type="{$type-value}">
      <head>
        <xsl:value-of select="normalize-space(tei:head)"/>
      </head>
      <xsl:for-each select="tei:p">
        <p>
          <xsl:value-of select="normalize-space(.)"/>
        </p>
      </xsl:for-each>
    </div>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- 4. Transform Komponenten head into div[@type='komponenten'] -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = 'Komponenten']]">
    <div type="komponenten">
      <p>
        <xsl:value-of select="normalize-space(tei:p)"/>
      </p>
    </div>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- 5. Transform Beilagen head into div[@type='beilagen'];
          transform paragraphs into list items -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = 'Beilagen:']]">
    <div type="beilagen">
      <head>
        <xsl:value-of select="normalize-space(tei:head)"/>
      </head>
      <list rend="#endash">
        <xsl:for-each select="tei:p">
          <item>
            <!-- process only element children, no whitespace;
            only apply templates of beilagen mode -->
            <xsl:apply-templates select="*" mode="beilagen"/>
          </item>
        </xsl:for-each>
      </list>
    </div>
  </xsl:template>

  <!-- beilagen mode: suppress original list marker -->
  <xsl:template match="tei:hi[starts-with(normalize-space(.), '–')]" mode="beilagen"/>

  <!-- beilagen mode: strip hi wrapper, keep text as-is -->
  <xsl:template match="tei:hi" mode="beilagen">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- beilagen mode: map internal ref targets to agenda-item ID scheme -->
  <xsl:template match="tei:ref[starts-with(@target, '#')]" mode="beilagen">
    <xsl:variable name="top-number"
                  select="replace(@target, '#(\d+)\.?', '$1')"/>
    <xsl:variable name="padded-top"
                  select="format-number(number($top-number), '00')"/>
    <ref target="#{$krp-number}_top{$padded-top}">
      <xsl:value-of select="normalize-space(.)"/>
    </ref>
  </xsl:template>

  <!-- beilagen mode: map external ref targets to supplement ID scheme -->
  <xsl:template match="tei:ref[starts-with(@target, 'https://')]" mode="beilagen">
    <xsl:variable name="supplement-id"
                  select="replace(@target, 'https://', '')"/>
    <ref target="#{$supplement-id}">
      <xsl:value-of select="normalize-space(.)"/>
    </ref>
  </xsl:template>

</xsl:stylesheet>
