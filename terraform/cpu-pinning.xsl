<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:template match="@*|node()" name="identity">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>
    <xsl:template match="domain/*[1]">
    <xsl:if test="not(cputune)">
        <cputune>
            <vcpupin vcpu="0" cpuset="1"/>
            <vcpupin vcpu="1" cpuset="25"/>
            <vcpupin vcpu="2" cpuset="2"/>
            <vcpupin vcpu="3" cpuset="26"/>
            <emulatorpin cpuset="0,24"/>
        </cputune>
    </xsl:if>
    <xsl:call-template name="identity" />
    </xsl:template>
</xsl:stylesheet>