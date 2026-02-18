<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0" version="3.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all">
    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
    
    <xsl:template match="/">
        <TEI>
            <teiHeader>
                <fileDesc>
                    <titleStmt>
                        <title level="a" type="main">Kabinettsprotokoll Nr. <xsl:value-of select=".//tei:titlePage/tei:docTitle/tei:titlePart[1]/text()"/>, <xsl:value-of select="//tei:titlePage/tei:docTitle/tei:titlePart[2]"/>
                        </title>
                        <title level="m" type="main">Abteilung I: (Deutsch-)Österreichischer Kabinettsrat 31. Oktober 1918 bis 7. Juli 1920</title>
                        <title level="m" type="main" n="01">Abteilung I</title><!-- suggest: merge @n into above; drop line -->
                        <title level="m" type="sub" n="3">Band 3</title><!-- suggest: merge @n and content into below; drop line -->
                        <title level="m" type="sub">Kabinett Dr. Karl Renner 1. Juli 1919 bis 30. Dezember 1919</title>
                        <title level="m" type="dates" from="1919-07-01" to="1919-12-30"/><!-- suggest: merge @from and @to into above; drop @type='dates' -->
                        <meeting>
                            <placeName key="https://d-nb.info/gnd/4066009-6">Wien</placeName><!-- clarify: @key vs @ref pointers --><!-- minor: introduce @key -->
                            <orgName key="">Kabinettsrat</orgName>
                            <date when-iso="1919-11-25"/><!-- major: drop content; major: replace @when -->
                        </meeting>
                        <editor key="https://d-nb.info/gnd/131679384"><!-- major: drop @ref (clarify: dangling pointers); major: drop @role='editor' -->
                            <persName>
                                <forename>Richard</forename>
                                <surname>Lein</surname>
                            </persName>
                            <affiliation key="https://d-nb.info/gnd/1026192285">Universität Wien, Institut für Rechts- und Verfassungsgeschichte</affiliation>
                            <idno type="ORCID">0000-0002-7502-0503</idno>
                        </editor>
                        <editor key="https://d-nb.info/gnd/1156925525"><!-- major: drop @ref (clarify: dangling pointers); major: drop @role='editor' --><!-- needs check -->
                            <persName>
                                <forename>Stefan</forename>
                                <surname>Wedrac</surname>
                            </persName>
                            <affiliation key="https://d-nb.info/gnd/1026192285">Universität Wien, Institut für Rechts- und Verfassungsgeschichte</affiliation>
                            <idno type="ORCID">0000-0003-2793-3946</idno>
                        </editor>
                        <funder key="https://d-nb.info/gnd/2054142-9">Österreichischer Wissenschaftsfonds FWF
                            <idno type="project">PAT1495024</idno>
                        </funder><!-- major: drop @n -->
                        <respStmt>
                            <resp>Projektverantwortung: </resp>
                            <name><rs type="institution" key="http://d-nb.info/gnd/1026192285">Universität Wien, Institut für Rechts- und Verfassungsgeschichte</rs></name><!-- major: replace @ref with @key --><!-- needs check -->
                        </respStmt>
                        <respStmt>
                            <resp>Digitalisierung der gedruckten Quellen: </resp><!-- minor: introduce colon -->
                            <name><rs type="institution" key="https://d-nb.info/gnd/2068748-5">Verlag der Österreichischen Akademie der Wissenschaften</rs></name><!-- major: replace @ref with @key -->
                        </respStmt>
                        <respStmt>
                            <resp>TEI-Datenmodellierung: </resp><!-- minor: introduce colon; change resp content -->
                            <persName><!-- major: drop @ref (clarify: dangling pointers) -->
                                <forename>Timo</forename>
                                <surname>Frühwirth</surname>, <affiliation key="https://d-nb.info/gnd/1123037736">Austrian Centre for Digital Humanities</affiliation>
                                <idno type="ORCID">0000-0002-3997-5193</idno><!-- major: introduce idno -->
                            </persName>
                        </respStmt>
                    </titleStmt>
                    <publicationStmt>
                        <publisher key="http://d-nb.info/gnd/1001454-8">Österreichische Akademie der Wissenschaften</publisher>
                        <date when="2028"/>
                        <availability status="free">
                            <licence target="https://creativecommons.org/licenses/by/4.0/deed.de">Lizenziert unter CC-BY-4.0 (https://creativecommons.org/licenses/by/4.0/deed.de)</licence>
                        </availability>
                    </publicationStmt>                
                    <sourceDesc>
                        <bibl>Quellbestand: AT-OeStA/AdR MRang MR 1Rep KRP Kabinettsratsprotokolle, 1918-1920 (Teilbestand) <ref target="https://www.archivinformationssystem.at/detail.aspx?id=5465">https://www.archivinformationssystem.at/detail.aspx?id=5465</ref></bibl>
                        <msDesc>
                            <msIdentifier><!-- major: introduce institution, repository, collection; drop idno -->
                                <institution key="https://d-nb.info/gnd/37748-X">AT-OeStA Österreichisches Staatsarchiv (Archiv (ÖStA))</institution>
                                <repository key="https://d-nb.info/gnd/1601181-8">AT-OeStA/AdR Archiv der Republik, 1918- (Abteilung)</repository>
                                <collection>AT-OeStA/AdR MRang MR 1Rep Ministerrat 1. Republik, 1918 - 1938 (Bestand)</collection>
                            </msIdentifier>
                        </msDesc>
                    </sourceDesc>
                </fileDesc>
                <profileDesc>
                    <abstract>
                        <p><!--to be generated--></p>
                    </abstract>
                </profileDesc>
            </teiHeader>
            <text>
                <body>
                    <div type="document">
                        <head type="document"><!-- major: drop @corresp -->
                            <title type="num"><xsl:value-of select=".//tei:titlePage/tei:docTitle/tei:titlePart[1]/text()"/></title>
                            <title type="date"><xsl:value-of select=".//tei:titlePage/tei:docTitle/tei:titlePart[2]"/></title>
                            <date>
                                <xsl:attribute name="when-iso"><xsl:value-of select="normalize-space(tokenize(.//tei:titlePage/tei:docTitle/tei:titlePart[2]/text(), '\]')[last()])"/></xsl:attribute>
                            </date>
                        </head>
                        <div type="regest">
                            <head>Regest</head>
                            <div type="meeting">
                                <head>Meeting</head>
                                <table>
                                <xsl:for-each select=".//tei:body/tei:div[1]/tei:div">
                                    <row n="{replace(lower-case(normalize-space(string-join(./tei:head//text()))), ':', '')}">
                                        <cell role="label">
                                            <xsl:apply-templates select="./tei:head"/>
                                        </cell>
                                        <cell role="data">
                                            <xsl:value-of select="./tei:p"/>
                                        </cell>
                                    </row>
                                </xsl:for-each>
                                </table>
                            </div>
                            <div type="dossier">
                               <head>Dossier</head>
                               <div><xsl:apply-templates select=".//tei:body/tei:div[2]//tei:p"></xsl:apply-templates></div>
                           </div>
                            <div type="toc">
                                <meeting>
                                    <list type="agenda">
                                        <head>Inhalt:</head>
                                        <xsl:for-each select=".//tei:list[1]//tei:item">
                                            <item>
                                                <label>
                                                    <num n="{position()}"><xsl:value-of select="position()"/>.</num>
                                                    <ref target="{'#top_'||position()}">
                                                        <xsl:value-of select="normalize-space(.)"/>
                                                    </ref>
                                                </label>
                                            </item>
                                        </xsl:for-each>
                                    </list>
                                </meeting>
                            </div>
                            <div type="beilagen">
                                <head>Beilagen</head>
                                <xsl:copy-of select=".//tei:div[./tei:head[./text() eq 'Beilagen:']]/tei:p"/>
                            </div>
                        </div>
                        <div type="protocoll">
                            <head>Protokoll</head>
                            <xsl:for-each select=".//tei:div[./tei:head[1][./text()[1] eq 'Protokoll']]/tei:div">
                                <xsl:copy-of select="."></xsl:copy-of>
                            </xsl:for-each>
                        </div>
                    </div>
                </body>
            </text>
        </TEI>
    </xsl:template>

    <xsl:template match="tei:p"><p><xsl:apply-templates/></p></xsl:template>
    
    <xsl:template match="tei:list">
        <list>
            <xsl:apply-templates/>
        </list>
    </xsl:template>
    
    <xsl:template match="tei:item">
        <item>
            <xsl:apply-templates/>
        </item>
    </xsl:template>
</xsl:stylesheet>