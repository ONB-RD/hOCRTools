<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:h="http://www.w3.org/1999/xhtml"
    xmlns:o="http://www.onb.ac.at/lib/xslt" exclude-result-prefixes="xs" version="3.0">
    
    <xsl:import href="hOCRUtil.xsl"/>
    
    <!--<xsl:strip-space elements="*"/>-->
    <xsl:template match="text()"/>
    <xsl:output method="text"/>
    
    <xsl:param name="pagenumber">
        <xsl:value-of select="substring-before(/h:html/h:head/h:title,'.html')"/>
    </xsl:param>

    <xsl:param name="barcode"/>
    <xsl:param name="iiifBaseURI"/>
    <!--
        $aspectThresholdIllustration: float defining the factor of how much
        bigger the taller edge of the illustration might be such that it is an
        Illustration and not a GraphicalElement as delimiters typically are.
        default: 5, cannot be 0
    -->
    <xsl:param name="aspectThresholdIllustration" as="xs:float">5</xsl:param>
    <xsl:variable name="aspectThresholdIllustrationDivisor" as="xs:float">
        <xsl:choose>
            <xsl:when test="$aspectThresholdIllustration &lt; 0">
                <xsl:value-of select="xs:float(1) div $aspectThresholdIllustration"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$aspectThresholdIllustration"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>



    <xsl:template match="h:html">
        <xsl:apply-templates select="h:body/*"/>
    </xsl:template>

    <xsl:template match="h:*[@class = 'ocr_page']">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- process ocr_par, for GBS purposes empty (printing characters present //text()) blocks are output as either GraphicalElement or Illustration
    all other ocr_par are output as TextBlock
    -->
    <xsl:template match="h:*[@class = 'ocr_par']">
        <xsl:variable name="blocktype">
            <xsl:choose>
                <xsl:when test="matches(., '\p{L}|\p{N}|\p{S}|\p{P}')">TextBlock</xsl:when>
                <!-- nested, as we don't need the variables at top level -->
                <xsl:otherwise>
                    <xsl:variable name="bbox">
                        <xsl:call-template name="getBbox"/>
                    </xsl:variable>
                    <xsl:variable name="aspectRatio"
                        select="xs:float(o:bboxGetWidth($bbox)) div o:bboxGetHeight($bbox)"/>
                    <xsl:choose>
                        <xsl:when
                            test="$aspectRatio &gt; xs:float(1) div $aspectThresholdIllustrationDivisor and $aspectRatio &lt; $aspectThresholdIllustration"
                            >Illustration</xsl:when>
                        <!--<xsl:otherwise>GraphicalElement</xsl:otherwise>-->
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:if test="$blocktype eq 'Illustration'">
            <xsl:call-template name="makePositionAttributes"/>
        </xsl:if>
        <!--<xsl:attribute name="ID" select="concat('block_',generate-id(.))"/>-->
<!--        <xsl:if test="$blocktype eq 'TextBlock'">
            <xsl:apply-templates/>
        </xsl:if>-->
    </xsl:template>

    <!--
        make attributes WIDTH HEIGHT VPOS HPOS from hOCR bbox parameters 
        $titleElem: element with hOCR @title, defaults to.
        return: attribute()+
    -->
    <xsl:template name="makePositionAttributes">
        <!--<xsl:param name="titleElem" select="."/>-->
        <xsl:variable name="bbox">
            <xsl:call-template name="getBbox"/>
        </xsl:variable>
        <xsl:value-of select="$iiifBaseURI"/>
        <xsl:value-of select="$barcode"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="$pagenumber"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="o:bboxGetX($bbox)"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="o:bboxGetY($bbox)"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="o:bboxGetWidth($bbox)"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="o:bboxGetHeight($bbox)"/>
        <xsl:text>/pct:50/0/native.jpg&#xa;</xsl:text>
    </xsl:template>
    
</xsl:stylesheet>
