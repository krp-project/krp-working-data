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
  <!-- <xsl:variable name="krp-number"
                select="lower-case(replace($input-filename, '.*?(KRP-\d{3}).*', '$1'))"/> -->
  <xsl:variable name="krp-digits"
                select="replace($input-filename, '.*?KRP-(\d+).*', '$1', 'i')"/><!-- flag as case-insensitive for robustness -->
  <xsl:variable name="krp-number"
                select="concat('krp-', format-number(number($krp-digits), '0000'))"/>
  <xsl:variable name="header-path"
                select="concat('../../header-docs/', $krp-number, '_header.xml')"/>
  <xsl:variable name="top-header" select="('TOP', 'TOP-&#xDC;berschrift')"/><!-- allow for both headers present in model DOCXs -->
  <xsl:variable name="shorthand-header" select="('Stenogramm', 'Stenogramme')" /><!-- allow for both headers present in model DOCXs -->

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
      <!-- <xsl:copy-of select="$header-doc/tei:TEI/tei:teiHeader"/> -->
      <!-- hand header content to template system -->
      <xsl:apply-templates select="$header-doc/tei:TEI/tei:teiHeader"/>
      <!-- apply upconversion to text element in input doc (converted from DOCX with TEIGarage) -->
      <xsl:apply-templates select="$input-text"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- Update TEI-header revisionDesc -->
  <!-- ================================================================== -->
  
  <xsl:template match="tei:revisionDesc">
    <!-- copy revisionDesc element with all attributes -->
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <!-- add change element re TEI-XML upconversion -->
      <change who="#tfruehwirth" when-iso="{format-date(current-date(), '[Y]-[M01]-[D01]')}">TEIGarage output upconverted with upconvert.xsl</change>
      <!-- process existing change element -->
      <xsl:apply-templates select="node()"/>
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
  <xsl:template match="tei:body//tei:p/text()[not(normalize-space())]"/><!-- not(normalize-space()) is true when text is whitespace-only -->
  
  <!-- strip italic/bold DOCX formatting; process children without preserving wrapper -->
  <xsl:template match="tei:hi[(contains(@rend, 'italic') or contains(@rend, 'bold')) and not(contains(@rend, 'underline')) and not(contains(@rend, 'strikethrough'))]">
    <xsl:choose>
      <!-- preserve italic formatting in editorial annotations -->
      <xsl:when test="contains(@rend, 'italic') and ancestor::tei:note">
        <hi rend="#i"><xsl:apply-templates/></hi>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
    
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
  
  <!-- drop pretty-print whitespace between seg fragments in <hi rend="Char_Style_N">-<seg> clusters -->
  <!-- note: when a split falls between two words, their space is dropped too and the words fuse;
       not detectable automatically and unfixable here. -->
  <xsl:strip-space elements="tei:hi tei:seg"/>
  
  <!-- strip character-style hi wrapper; process children (not value-of),
       so nested markup (like page markers) still reaches its templates -->
  <xsl:template match="tei:hi[starts-with(@rend, 'Char_Style_')]">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- strip seg wrapper inside character-style hi wrapper;
       leave page markers and transcribers' notes intact -->
  <xsl:template match="tei:hi[starts-with(@rend, 'Char_Style_')]/tei:seg
    [not(contains(@rend, 'background(green)')) and not(contains(@rend, 'background(yellow)'))]">
    <xsl:apply-templates/>
  </xsl:template>
   
  <!-- ================================================================== -->
  <!-- Transform page-beginning information -->
  <!-- ================================================================== -->
  
  <!-- drop empty <pb> elements from transcribers' pagebreaks for visual separation
       of transcription parts; reserve <pb> for source pagebreaks-->
  <xsl:template match="tei:pb[not(@*)]"/>
  
  <!-- note: Saxon indent="yes" inserts whitespace between parent tags and
       adjacent child elements in mixed content (including adding newlines
       before </p> when pb is the last element in the paragraph) - this is
       expected and accepted -->
  <!-- <xsl:template match="tei:hi[@rend='background(green)']">
    <xsl:variable name="page-number"
      select="replace(., '^.*?(\d+)\|$', '$1')"/>
    <pb n="{number($page-number)}"/>
  </xsl:template> -->
  <!-- one <pb> per marker: split on "|" for multiple markers in same <hi>;
       preserve full image ID in @facs -->
  <xsl:template match="tei:hi[@rend='background(green)']">
    <xsl:for-each select="tokenize(., '\|')[normalize-space()]">
      <pb facs="{normalize-space(.)}"/>
    </xsl:for-each>
  </xsl:template>
  
  <!-- if page marker is split across several <seg>s,
       target first and join all segments -->
  <xsl:template match="tei:seg[contains(@rend,'background(green)')]
    [not(preceding-sibling::tei:seg[contains(@rend,'background(green)')])]">
    <xsl:for-each select="tokenize(
        string-join(../tei:seg[contains(@rend,'background(green)')], ''), '\|')[normalize-space()]">
      <pb facs="{normalize-space(.)}"/>
    </xsl:for-each>
  </xsl:template>
  <!-- drop following segs of same page marker that are already folded in -->
  <xsl:template match="tei:seg[contains(@rend,'background(green)')]
    [preceding-sibling::tei:seg[contains(@rend,'background(green)')]]"/>

  <!-- ================================================================== -->
  <!-- Strip transcribers' notes -->
  <!-- ================================================================== -->
  
  <!-- <xsl:template match="tei:hi[@rend='background(yellow)']">
  </xsl:template> -->

  <!-- ================================================================== -->
  <!-- Upconvert input XML's text body -->
  <!-- ================================================================== -->

  <!-- suppress front element -->
  <xsl:template match="tei:front"/>
  
  <!-- suppress title-and-subtitle div if present -->
  <xsl:template match="tei:body/tei:div[tei:p[@rend='Title']]"/>

  <xsl:template match="tei:body">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <!-- save body content before xsl:copy changes context -->
      <xsl:variable name="body-content" select="node()"/>
      <!-- save front element before xsl:copy changes context -->
      <xsl:variable name="front" select="../tei:front"/>
      <xsl:variable name="title-container" select="if ($front)
                then $front//tei:titlePart[@type='Title']
                else ($body-content/self::tei:div)[1]/tei:p[@rend='Title']"/><!-- allow for both protcol-title containers present in model DOCXs -->
      <xsl:variable name="subtitle-container" select="if ($front)
                then $front//tei:titlePart[@type='Subtitle']
                else ($body-content/self::tei:div)[1]/tei:p[@rend='Subtitle']"/><!-- allow for both protcol-subtitle containers present in model DOCXs -->
      <!-- wrap body content in outermost div from TEI-header document -->
      <xsl:copy select="$header-doc//tei:body/tei:div">
        <xsl:copy-of select="$header-doc//tei:body/tei:div/@*"/>
        <!-- ================================================================== -->
        <!-- 1. Transform input-XML's front titlePage into document head -->
        <!-- ================================================================== -->
        <head type="dokument">
          <title type="num">
            <xsl:value-of select="normalize-space(
                string-join($title-container//text()[not(ancestor::tei:note)], ''))"/><!-- grab text, but skip footnote -->
            <xsl:apply-templates select="$title-container//tei:note[@place='foot']"/><!-- pass through footnote -->
          </title>
          <title type="desc"><!-- changed from MRP-style @type='descr' -->
            <xsl:value-of select="normalize-space(
                string-join($subtitle-container//text()[not(ancestor::tei:hi[contains(@rend,'background(green)')])], ''))"/><!-- grab text, but skip page markers -->
          </title>
        </head>
        <xsl:apply-templates select="$subtitle-container//tei:hi[contains(@rend,'background(green)')]"/><!-- pass through page markers from subtitle container -->
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
    <!-- <xsl:variable name="top-number"
                  select="replace(@target, '#(\d+)\.?', '$1')"/> -->
    <xsl:variable name="top-number"
      select="replace(@target, '^#(\d+).*$', '$1')"/><!-- allow for both modes of internal-ref targeting present in model DOCXs -->
    <xsl:variable name="padded-top"
                  select="format-number(number($top-number), '00')"/>
    <ref target="#{$krp-number}_top{$padded-top}">
      <xsl:value-of select="normalize-space(.)"/>
    </ref>
  </xsl:template>

  <!-- beilagen mode: map external ref targets to supplement ID scheme -->
  <xsl:template match="tei:ref[starts-with(@target, 'https://') or matches(@target, '^krp-\d{4}_b\d{2}$')]" mode="beilagen"><!-- allow for both modes of external-ref targeting present in model DOCXs -->
    <!-- <xsl:variable name="supplement-id"
                  select="replace(@target, 'https://', '')"/> -->
       <xsl:choose>
        <xsl:when test="starts-with(@target, 'https://')">
          <xsl:variable name="raw" select="replace(@target, 'https://', '')"/>
          <xsl:variable name="digits" select="replace($raw, '^krp-(\d+)_.*$', '$1')"/>
          <xsl:variable name="suffix" select="replace($raw, '^krp-\d+(_.*)$', '$1')"/>
          <xsl:variable name="supplement-id"
            select="concat('krp-', format-number(number($digits), '0000'), $suffix)"/>
          <ref target="#{$supplement-id}"><!-- todo: subject to change according to IIIF setup -->
            <xsl:value-of select="normalize-space(.)"/>
          </ref>
        </xsl:when>
        <xsl:when test="matches(@target, '^krp-\d{4}_b\d{2}$')">
          <xsl:variable name="supplement-id" select="@target"/>
          <ref target="#{$supplement-id}">
            <xsl:value-of select="normalize-space(.)"/>
          </ref>
        </xsl:when>
        <!-- fail-loud pass through -->
        <xsl:otherwise>
          <xsl:copy-of select="."/>
        </xsl:otherwise>
       </xsl:choose>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- 7. Transform Protokoll head into div[@type='protokoll'] -->
  <!-- ================================================================== -->
  <xsl:template match="tei:body/tei:div[tei:head[normalize-space(.) = 'Protokoll']]"><!-- prevent mismatching with supplement divs with same -->
    <div type="protokoll">
      <xsl:apply-templates select="tei:div"/>
    </div>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- 8. Label agenda-item divs -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = 'Protokoll']]/tei:div[tei:div/tei:head[normalize-space(.) = $top-header]]">
    <!-- capture first number in string -->
    <xsl:variable name="top-number"
                  select="replace(normalize-space(tei:head), '^.*?(\d+).*$', '$1')"/>
    <xsl:variable name="padded-top" select="format-number(number($top-number), '00')"/>
    <div type="top" xml:id="{$krp-number}_top{$padded-top}"><!-- changed from MRP-style @type='agenda_item' -->
      <head>
        <label>
          <num n="{$top-number}">
            <xsl:value-of select="normalize-space(tei:head)"/>
          </num>
          <seg>
            <!-- collapse whitespace before period characters resulting from TEIGarage artefacts (related to DOCX formatting errors) -->
            <xsl:value-of select="replace(normalize-space(tei:div[tei:head[normalize-space(.) = $top-header]]/tei:p[1]), '\s+\.', '.')"/>
          </seg>
        </label>
      </head>
      <xsl:apply-templates select="tei:div[tei:head[normalize-space(.) = 'Text']]"/>
    </div>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- 9. Flatten structure within agenda-item divs -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = 'Protokoll']]/tei:div[tei:div/tei:head[normalize-space(.) = $top-header]]/tei:div[tei:head[normalize-space(.) = 'Text']]">
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
  <xsl:template match="tei:body/tei:div[tei:head[normalize-space(.) = 'Protokoll']]/tei:div[not(tei:div/tei:head[normalize-space(.) = $top-header])]">
    <xsl:variable name="padded-notop">
      <!-- number non-agenda-item siblings -->
      <xsl:number count="tei:div[not(tei:div/tei:head[normalize-space(.) = $top-header])]" format="01"/>
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
  <!-- 11. Transform Stenogramm(e) head into div[@type='stenogramme'] -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = $shorthand-header]]">
    <div type="stenogramme">
      <!-- filter out empty div nodes created by surplus DOCX whitespace -->
      <xsl:apply-templates select="tei:div[tei:head]"/>
    </div>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- 12. Label Stenogramm divs -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = $shorthand-header]]/tei:div">
    <!-- number divs through shorthand attribute value template -->
    <div n="{position()}">
      <xsl:variable name="descriptor" select="if (tei:head/tei:hi[2]) then tei:head/tei:hi[2] else tei:p[1]"/><!-- allow for both header provenances in model DOCXs -->
      <head>
        <xsl:value-of select="normalize-space($descriptor)"/>
      </head>
      <xsl:for-each select="tei:p except $descriptor | tei:list">
        <xsl:choose>
          <xsl:when test="self::tei:list">
            <xsl:apply-templates select="."/>
          </xsl:when>
          <xsl:otherwise>
            <p>
              <xsl:attribute name="n">
                <xsl:number count="tei:p except $descriptor"/>
              </xsl:attribute>
              <xsl:apply-templates/>
            </p>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </div>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- 13. Transform Anhänge head into div[@type='anhänge'] -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = 'Anh&#xE4;nge']]">
    <div type="anhänge">
      <xsl:apply-templates select="tei:p"/>
      <xsl:apply-templates select="tei:div"/>
    </div>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- 14. Streamline structure within Anhänge divs -->
  <!-- ================================================================== -->
  <xsl:template match="tei:div[tei:head[normalize-space(.) = 'Anh&#xE4;nge']]/tei:div">
    <xsl:variable name="anhang-n" select="position()"/>
    <div n="{$anhang-n}">
      <head>
        <xsl:value-of select="replace(normalize-space(tei:div[tei:head[normalize-space(.) = '&#xDC;berschrift']]/tei:p[1]), '\s+\.', '.')"/><!-- remove stray space before period resulting from TEI-Garage segmentation -->
      </head>
      <xsl:apply-templates select="tei:div except tei:div[tei:head[normalize-space(.) = '&#xDC;berschrift']]">
        <xsl:with-param name="anhang-n" select="$anhang-n" tunnel="yes"/>
      </xsl:apply-templates>
    </div>
  </xsl:template>
  
  <xsl:template
    match="tei:div[tei:head[normalize-space(.) = 'Anh&#xE4;nge']]/tei:div/tei:div except tei:div[tei:head[normalize-space(.) = '&#xDC;berschrift']]">
    <xsl:param name="anhang-n" tunnel="yes"/>
    <div>
      <xsl:variable name="div-head" select="lower-case(normalize-space(tei:head))"/>
      <xsl:attribute name="type" select="concat('a', format-number(number($anhang-n), '00'), '_', $div-head)"/>
      <xsl:for-each select="tei:p">
        <p>
          <xsl:apply-templates/>
        </p>
      </xsl:for-each>
      <xsl:for-each select="tei:div">
        <div>
          <xsl:variable name="div-head" select="lower-case(normalize-space(tei:head))"/>
          <xsl:attribute name="type" select="concat('a', format-number(number($anhang-n), '00'), '_', $div-head)"/>
          <xsl:for-each select="tei:p">
            <p>
              <xsl:apply-templates/>
            </p>
          </xsl:for-each>
        </div>
      </xsl:for-each>
    </div>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- 15. Reformat list using tab delimiter for labelling -->
  <!-- ================================================================== -->
  <!-- strip rend attribute from DOCX lists; pass through any other list -->
  <xsl:template match="tei:list[@rend]">
    <!-- create list wrapper to strip input attributes; process children -->
    <list>
      <xsl:apply-templates/>
    </list>
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
      <!-- assemble item node when tab is nested inside descendant element
           (such as in the case of additional character formatting) -->
      <xsl:when test="contains(string(.), '&#x9;')"><!-- test for tab across all (concatenated) descendant text nodes -->
        <xsl:variable name="full-text" select="string-join(descendant::text()[normalize-space()], '')"/><!-- concatenate text nodes anywhere in this element with no separator, drop whitespace nodes -->
        <item>
          <xsl:attribute name="n">
            <xsl:number count="tei:item"/>
          </xsl:attribute>
          <label><xsl:value-of select="normalize-space(substring-before($full-text, '&#x9;'))"/></label>
          <!-- collapse tab into single space -->
          <xsl:text> </xsl:text>
          <xsl:value-of select="normalize-space(substring-after($full-text, '&#x9;'))"/>
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
  
  <!-- ================================================================== -->
  <!-- 16. Strip TEIGarage style information from table -->
  <!-- ================================================================== -->
  <xsl:template match="tei:table">
    <table>
      <xsl:copy-of select="@cols | @rows"/><!-- preserve @cols and @rows attributes if present -->
      <xsl:apply-templates/>
    </table>
  </xsl:template>
  
  <xsl:template match="tei:table/tei:row">
    <row>
      <xsl:copy-of select="@cols | @rows"/>
      <xsl:apply-templates/>
    </row>
  </xsl:template>
  
  <xsl:template match="tei:table/tei:row/tei:cell"> 
    <cell>
      <xsl:copy-of select="@cols | @rows"/>
      <xsl:apply-templates/>
    </cell>
  </xsl:template>
  
  <!-- ================================================================== -->
  <!-- 17. Align footnotes with MRP data model -->
  <!-- ================================================================== -->
  <xsl:template match="tei:body//tei:note">
    <note type="footnote">
      <xsl:copy-of select="@n"/>
      <xsl:attribute name="target" select="concat('#fn_', $krp-number, '_', @n)"/>
      <xsl:apply-templates/>
    </note>
  </xsl:template>

  <xsl:template match="tei:body//tei:note/tei:p/text()[1][normalize-space()]"><!-- target not-whitespace-only text nodes to prevent conflict with <xsl:template match="tei:body//tei:p/text()[not(normalize-space())]"/> above -->
    <!-- strip leading space from DOCX formatting -->
    <xsl:value-of select="replace(., '^\s+', '')"/>
  </xsl:template>

  <xsl:template match="tei:body//tei:note/tei:p">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
