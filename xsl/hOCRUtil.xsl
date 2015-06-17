<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:o="http://www.onb.ac.at/lib/xslt"
    exclude-result-prefixes="xs o"
    version="2.0">
    
    <!-- 
        This library serves as a place to collect the definition of named templates
        and functions for the general use for processing hOCR.
    -->
    
    <!--
        $OCRHOffset: offset by how much the OCR is off on the horizontal axis.
                     This will be subtracted from the respective values of the
                     of the OCR bounding box.             
     -->
    <xsl:param name="OCRHOffset" as="xs:integer">0</xsl:param>
    <!--
        $OCRVOffset: offset by how much the OCR is off on the vertical axis.
                     This will be subtracted from the respective values of the
                     OCR bounding box.             
     -->
    <xsl:param name="OCRVOffset" as="xs:integer">0</xsl:param>
    
    <!-- 
        set of function to get the individual dimensions from hOCR bbox 
        $bbox is a sequence of o:val elements with the top left, bottom right
        of the bbox.
        -> one getter for
        - width
        - height
        - x-position
        - y-position
        return: xs:float
    -->
    <xsl:function name="o:bboxGetWidth" as="xs:float">
        <xsl:param name="bbox"/>
        <xsl:value-of select="abs($bbox/o:val[3] - $bbox/o:val[1])"/>
    </xsl:function>
    <xsl:function name="o:bboxGetHeight" as="xs:float">
        <xsl:param name="bbox"/>
        <xsl:value-of select="abs($bbox/o:val[4] - $bbox/o:val[2])"/>
    </xsl:function>
    <xsl:function name="o:bboxGetX" as="xs:float">
        <xsl:param name="bbox"/>
        <xsl:value-of select="min($bbox/o:val[1]|$bbox/o:val[3]) - $OCRHOffset"></xsl:value-of>
    </xsl:function>
    <xsl:function name="o:bboxGetY" as="xs:float">
        <xsl:param name="bbox"/>
        <xsl:value-of select="min($bbox/o:val[2]|$bbox/o:val[4]) - $OCRVOffset"/>
    </xsl:function>


    <!-- 
        template getAggregateDimensions: gets the minimal and maximal x,y values
        to establish the printed area covered by a sequence of elements.
        $elems: sequence of elements to determine printed area,
                defaults to children of context with @title matching 'bbox '
        return: sequence of four element(o:val)
    --> 
    <xsl:template name="getAggregateDimensions">
        <!-- FIX: should we use .//* here? -->
        <xsl:param name="elems" select="./*[contains(@title, 'bbox ')]"/>
        <xsl:variable name="valSets">
            <xsl:for-each select="$elems">
                <o:set>
                    <xsl:call-template name="getBbox"/>
                </o:set>
            </xsl:for-each>
            <!-- if there is nothing on the page -->
            <xsl:if test="empty($elems)">
                <o:set>
                    <o:val>0</o:val>
                    <o:val>0</o:val>
                    <o:val>0</o:val>
                    <o:val>0</o:val>
                </o:set>
            </xsl:if>
        </xsl:variable>
        <o:val>
            <xsl:value-of select="min($valSets/o:set/o:val[1]|$valSets/o:set/o:val[3])"/>
        </o:val>
        <o:val>
            <xsl:value-of select="min($valSets/o:set/o:val[2]|$valSets/o:set/o:val[4])"/>
        </o:val>
        <o:val>
            <xsl:value-of select="max($valSets/o:set/o:val[1]|$valSets/o:set/o:val[3])"/>
        </o:val>
        <o:val>
            <xsl:value-of select="max($valSets/o:set/o:val[2]|$valSets/o:set/o:val[4])"/>
        </o:val>
    </xsl:template>
    
    <!-- 
        template getWconf: gets the word confidence from OCR engine
        $titleElem: element with @title supposedly containing x_wconf
                    defaults to context node
        return: element(o:val)
    -->    
    <xsl:template name="getWconf">
        <xsl:param name="titleElem" select="."/>
        <xsl:call-template name="getTitleParam">
            <xsl:with-param name="titleElem" select="$titleElem"/>
            <xsl:with-param name="paramName">x_wconf</xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <!-- 
        template getWconf: gets the word confidence from OCR engine
        $titleElem: element with @title supposedly containing x_wconf,
                    defaults to context node
        return: element(o:val)+
                (o:val)[1]: x top-left
                (o:val)[2]: y top-left
                (o:val)[3]: x bottom-right
                (o:val)[4]: y bottom-right
    --> 
    <xsl:template name="getBbox">
        <xsl:param name="titleElem" select="."/>
        <xsl:call-template name="getTitleParam">
            <xsl:with-param name="titleElem" select="$titleElem"/>
            <xsl:with-param name="paramName">bbox</xsl:with-param>
        </xsl:call-template>
    </xsl:template>
 
    <!-- 
        template getPpageno: gets number of physical page
        $titleElem: element with @title supposedly containing ppageno,
                    defaults to context node
        return: element(o:val)        
    --> 
    <xsl:template name="getPpageno">
        <xsl:param name="titleElem" select="."/>
        <xsl:call-template name="getTitleParam">
            <xsl:with-param name="titleElem" select="$titleElem"/>
            <xsl:with-param name="paramName">ppageno</xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <!--
        template getTitleParam: gets named parameter from @title attribute
    -->
    <xsl:template name="getTitleParam">
        <xsl:param name="titleElem"/>
        <xsl:param name="paramName"/>
        <xsl:param name="delim"><xsl:text> </xsl:text></xsl:param>
        <xsl:param name="terminator">;</xsl:param>
        <xsl:param name="title" select="$titleElem/@title"/>
        <xsl:if test="o:hasTitleParam($title, $paramName)">
            <xsl:variable name="str">
                <xsl:choose>
                    <xsl:when test="contains(substring-after($title, concat($paramName, ' ')),$terminator)">
                        <xsl:value-of select="substring-before(substring-after($title, concat($paramName, ' ')),$terminator)"/>    
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="substring-after($title, concat($paramName,' '))"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:call-template name="tokenize">
                <xsl:with-param name="str" select="$str"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:function name="o:hasTitleParam" as="xs:boolean">
        <xsl:param name="title"/>
        <xsl:param name="paramName"/>
        <xsl:value-of select="contains($title, concat($paramName, ' '))"/>
    </xsl:function>
    
    <xsl:template name="tokenize">
        <xsl:param name="str"/>
        <xsl:param name="delim"><xsl:text> </xsl:text></xsl:param>
        <xsl:variable name="part" select="substring-before($str, $delim)"/>
        <!--         <xsl:message>str <xsl:value-of select="$str"/></xsl:message>
        <xsl:message>part <xsl:value-of select="$part"/></xsl:message> -->
        <xsl:choose>
            <xsl:when test="string-length($part) > 0">
                <!--<xsl:message>recursing</xsl:message>-->
                <o:val>
                    <xsl:value-of select="$part"/>
                </o:val>
                <xsl:call-template name="tokenize">
                    <xsl:with-param name="str" select="substring-after($str, $delim)"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="string-length($str) > 0">
                <!-- <xsl:message>finishing</xsl:message> -->
                <o:val>
                    <xsl:value-of select="$str"/>
                </o:val>
            </xsl:when>
        </xsl:choose>
        
    </xsl:template>
</xsl:stylesheet>