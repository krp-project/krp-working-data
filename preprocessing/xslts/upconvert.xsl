<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.tei-c.org/ns/1.0"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                version="3.0"
                exclude-result-prefixes="tei">

  <xsl:output method="xml" indent="yes"/>

  <!-- identity transform: recursively copy as-is by default; requires XSLT 3.0 -->
  <xsl:mode on-no-match="shallow-copy"/>

  <!-- ================================================================== -->
  <!-- Obtain constants and TEI-header-document node -->
  <!-- ================================================================== -->

  <!-- get constants from input filename -->
  <xsl:variable name="input-filename" select="tokenize(document-uri(/), '/')[last()]"/>
  <xsl:variable name="krp-number"
                select="lower-case(replace($input-filename, '.*?(KRP-\d{3}).*', '$1'))"/>
  <xsl:variable name="header-path"
                select="concat('../../header-docs/', $krp-number, '_header.xml')"/>

  <!-- Load and parse header doc, return document node; otherwise fail -->
  <xsl:variable name="header-doc" select="document($header-path)"/>

  <!-- ================================================================== -->
  <!-- Kick off processing;
       copy processing instructions from TEI-header document -->
  <!-- ================================================================== -->

  <xsl:template match="/">
    <!-- copy processing instructions from header doc -->
    <xsl:copy-of select="$header-doc/processing-instruction()"/>
    <!-- insert newline -->
    <xsl:text>&#10;</xsl:text>
    <xsl:apply-templates select="tei:TEI"/>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- Merge TEI header from TEI-header document with input text body -->
  <!-- ================================================================== -->

  <xsl:template match="tei:TEI">
    <!-- save reference to input's text element before xsl:copy changes context -->
    <xsl:variable name="input-text" select="tei:text"/>
    <!-- create root element from header doc -->
    <xsl:copy select="$header-doc/tei:TEI">
      <!-- copy full root-element attributes from header doc -->
      <xsl:copy-of select="$header-doc/tei:TEI/@*"/>
      <!-- copy full TEI header from header doc;
           note: TEI default attributes may be expanded
           into the XML output - this is expected and accepted -->
      <xsl:copy-of select="$header-doc/tei:TEI/tei:teiHeader"/>
      <!-- apply upconversion to text element in input doc (converted from DOCX with TEIGarage) -->
      <xsl:apply-templates select="$input-text"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- Clean up TEIGarage formatting -->
  <!-- ================================================================== -->
  
  <!-- process children of style-information hi elements without preserving wrapper -->
  <xsl:template match="tei:hi[@style and not(@rend)]">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- suppress whitespace nodes resulting from discarding hi wrappers -->
  <xsl:template match="tei:p/text()[not(normalize-space())]"/><!-- not(normalize-space()) is true when text is whitespace-only -->
  
  <!-- strip italic/bold DOCX formatting noise; process children without preserving wrapper -->
  <xsl:template match="tei:hi[(contains(@rend, 'italic') or contains(@rend, 'bold')) and not(contains(@rend, 'underline')) and not(contains(@rend, 'strikethrough'))]">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- handle underlines and strikethroughs, either individual or combined -->
  <xsl:template match="tei:hi[contains(@rend, 'underline') and not(contains(@rend, 'strikethrough'))]">
    <hi rend="#u"><xsl:apply-templates/></hi>
  </xsl:template>
  
  <xsl:template match="tei:hi[contains(@rend, 'strikethrough') and not(contains(@rend, 'underline'))]">
    <hi rend="#s"><xsl:apply-templates/></hi>
  </xsl:template>
  
  <xsl:template match="tei:hi[contains(@rend, 'underline') and contains(@rend, 'strikethrough')]">
    <hi rend="#u"><hi rend="#s"><xsl:apply-templates/></hi></hi>
  </xsl:template>
   
  <!-- ================================================================== -->
  <!-- Transform page-beginning information -->
  <!-- ================================================================== -->
  
  <!-- note: Saxon indent="yes" inserts whitespace between parent tags and
       adjacent child elements in mixed content (including adding newlines
       before </p> when pb is the last element in the paragraph) - this is
       expected and accepted -->
  <xsl:template match="tei:hi[@rend='background(green)']">
    <xsl:variable name="page-number"
      select="replace(., '^.*?(\d+)\|$', '$1')"/>
    <pb n="{number($page-number)}"/>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- Upconvert input XML's text body -->
  <!-- ================================================================== -->

  <!-- suppress front element -->
  <xsl:template match="tei:front"/>

  <xsl:template match="tei:body">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <!-- save body content before xsl:copy changes context -->
      <xsl:variable name="body-content" select="node()"/>
      <!-- save front element before xsl:copy changes context -->
      <xsl:variable name="front" select="../tei:front"/>
      <!-- wrap body content in outermost div from TEI-header document -->
      <xsl:copy select="$header-doc//tei:body/tei:div">
        <xsl:copy-of select="$header-doc//tei:body/tei:div/@*"/>
        <!-- ================================================================== -->
        <!-- 1. Transform input-XML's front titlePage into document head -->
        <!-- ================================================================== -->
        <head type="dokument">
          <title type="num">
            <xsl:value-of select="normalize-space($front//tei:titlePart[@type='Title'])"/>
          </title>
          <title type="desc"><!-- changed from MRP-style @type='descr' -->
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
  <!-- 3. Derive types of Dokumentkopf-divs from heads -->
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
      <list>
        <xsl:for-each select="tei:p">
          <item>
            <!-- process only element children, no whitespace ("select='*'");
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
  
  <!-- ================================================================== -->
  <!-- 6. Transform reference targets in beilagen-mode context -->
  <!-- ================================================================== -->
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
    <ref target="#{$supplement-id}"><!-- todo: subject to change according to IIIF setup -->
      <xsl:value-of select="normalize-space(.)"/>
    </ref>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- 7. Transform Protokoll head into div[@type='protokoll'] -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = 'Protokoll']]">
    <div type="protokoll">
      <xsl:apply-templates select="tei:div"/>
    </div>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- 8. Label agenda-item divs -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = 'Protokoll']]/tei:div[tei:div/tei:head[normalize-space(.) = 'TOP']]">
    <!-- capture first number in string -->
    <xsl:variable name="top-number"
                  select="replace(normalize-space(tei:head/tei:hi), '^.*?(\d+).*$', '$1')"/>
    <xsl:variable name="padded-top" select="format-number(number($top-number), '00')"/>
    <div type="top" xml:id="{$krp-number}_top{$padded-top}"><!-- changed from MRP-style @type='agenda_item' -->
      <head>
        <label>
          <num n="{$top-number}">
            <xsl:value-of select="normalize-space(tei:head/tei:hi)"/>
          </num>
          <seg>
            <!-- collapse whitespace before period characters resulting from TEIGarage artefacts (related to DOCX formatting errors) -->
            <xsl:value-of select="replace(normalize-space(tei:div[tei:head[normalize-space(.) = 'TOP']]/tei:p[1]), '\s+\.', '.')"/>
          </seg>
        </label>
      </head>
      <xsl:apply-templates select="tei:div[tei:head[normalize-space(.) = 'Text']]"/>
    </div>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- 9. Flatten structure within agenda-item divs -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = 'Protokoll']]/tei:div[tei:div/tei:head[normalize-space(.) = 'TOP']]/tei:div[tei:head[normalize-space(.) = 'Text']]">
    <xsl:for-each select="tei:p | tei:list">
      <xsl:choose>
        <xsl:when test="self::tei:list">
          <!-- apply templates to the list element -->
          <xsl:apply-templates select="."/>
        </xsl:when>
        <xsl:otherwise>
          <!-- create paragraph wrapper to strip input attributes; process children -->
          <p>
            <xsl:apply-templates/>
          </p>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- 10. Label non-agenda-item divs and flatten structure -->
  <!-- ================================================================== -->
  <!-- catch Protokoll child div that has no sub-div with a "TOP" header -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = 'Protokoll']]/tei:div[not(tei:div/tei:head[normalize-space(.) = 'TOP'])]">
    <xsl:variable name="padded-notop">
      <!-- number non-agenda-item siblings -->
      <xsl:number count="tei:div[not(tei:div/tei:head[normalize-space(.) = 'TOP'])]" format="01"/>
    </xsl:variable>
    <div type="notop" xml:id="{$krp-number}_notop{$padded-notop}">
      <head>
        <label>
          <xsl:value-of select="normalize-space(tei:head)"/>
        </label>
      </head>
      <xsl:for-each select="tei:div[tei:head[normalize-space(.) = 'Text']]/(tei:p | tei:list)">
        <xsl:choose>
          <xsl:when test="self::tei:list">
            <xsl:apply-templates select="."/>
          </xsl:when>
          <xsl:otherwise>
            <p>
              <xsl:apply-templates/>
            </p>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </div>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- 11. Transform Stenogramm head into div[@type='stenogramm'] -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = 'Stenogramm']]">
    <div type="stenogramm">
      <!-- filter out empty div nodes created by surplus DOCX whitespace -->
      <xsl:apply-templates select="tei:div[tei:head]"/>
    </div>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- 12. Label Stenogramm divs -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = 'Stenogramm']]/tei:div">
    <!-- number divs through shorthand attribute value template -->
    <div n="{position()}">
      <head>
        <xsl:value-of select="normalize-space(tei:head/tei:hi[2])"/>
      </head>
      <xsl:for-each select="tei:p | tei:list">
        <xsl:choose>
          <xsl:when test="self::tei:list">
            <xsl:apply-templates select="."/>
          </xsl:when>
          <xsl:otherwise>
            <p>
              <xsl:attribute name="n">
                <xsl:number count="tei:p"/>
              </xsl:attribute>
              <xsl:apply-templates/>
            </p>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </div>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- 13. Reformat list using tab delimiter for labelling -->
  <!-- ================================================================== -->
  <!-- strip rend attribute from DOCX lists; pass through any other list -->
  <xsl:template match="tei:list[@rend]">
    <xsl:choose>
      <xsl:when test="tei:item/tei:list">
        <!-- create list wrapper to strip input attributes; process children -->
        <list type="complex">
          <xsl:apply-templates/>
        </list>
      </xsl:when>
      <xsl:otherwise>
        <list type="simple">
          <xsl:apply-templates/>
        </list>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:list[@rend]/tei:item">
    <!-- capture first text node child of item's text content -->
    <xsl:variable name="text" select="text()[1]"/>
    <xsl:choose>
      <!-- test presence of tab character -->
      <xsl:when test="contains($text, '&#x9;')">
        <!-- assemble item node -->
        <item>
          <xsl:attribute name="n">
            <xsl:number count="tei:item"/>
          </xsl:attribute>
          <label><xsl:value-of select="substring-before($text, '&#x9;')"/></label>
          <!-- collapse tab into single space -->
          <xsl:text> </xsl:text>
          <xsl:value-of select="substring-after($text, '&#x9;')"/>
          <!-- process remaining child nodes (text or otherwise) after first text node -->
          <xsl:apply-templates select="node()[position() > 1]"/>
        </item>
      </xsl:when>
      <!-- fallback: if outside expected format, pass through as-is -->
      <xsl:otherwise>
        <item>
          <xsl:attribute name="n">
            <xsl:number count="tei:item"/>
          </xsl:attribute>
          <xsl:apply-templates/>
        </item>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
