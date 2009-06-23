<!--
NReco library (http://nreco.googlecode.com/)
Copyright 2008,2009 Vitaliy Fedorchenko
Distributed under the LGPL licence
 
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->	
<xsl:stylesheet version='1.0' 
				xmlns:xsl='http://www.w3.org/1999/XSL/Transform' 
				xmlns:msxsl="urn:schemas-microsoft-com:xslt" 
				xmlns:wr="urn:schemas-nreco:nreco:web:v1"
				xmlns:r="urn:schemas-nreco:nreco:core:v1"
				xmlns:e="urn:schemas-nreco:nreco:entity:v1"
				xmlns:d="urn:schemas-nreco:nicnet:dalc:v1"
				exclude-result-prefixes="msxsl">

<xsl:template match="e:entity-create-sql">
	<xsl:call-template name='component-definition'>
		<xsl:with-param name='name' select="@name"/>
		<xsl:with-param name='type'>NI.Winter.ReplacingFactory</xsl:with-param>
		<xsl:with-param name='injections'>
			<property name="TargetObject">
				<value>
					<xsl:apply-templates select="e:entity" mode="generate-mssql-create-sql"/>
				</value>
			</property>
		</xsl:with-param>
	</xsl:call-template>
</xsl:template>

<xsl:template match="e:dataset-factory">
	<xsl:call-template name='component-definition'>
		<xsl:with-param name='name' select="@name"/>
		<xsl:with-param name='type'>NI.Data.Dalc.DataSetFactory</xsl:with-param>
		<xsl:with-param name='injections'>
			<property name="Schemas">
				<list>
					<xsl:for-each select="e:entity">
						<entry>
							<component type="NI.Data.Dalc.DataSetFactory+SchemaDescriptor" singleton="false">
								<property name="SourceNames"><list><entry><value><xsl:value-of select="@name"/></value></entry></list></property>
								<property name="XmlSchema">
									<xml>
										<xsl:apply-templates select="." mode="generate-dataset-xmlschema"/>
									</xml>
								</property>
							</component>
						</entry>
					</xsl:for-each>
				</list>
			</property>
		</xsl:with-param>
	</xsl:call-template>
</xsl:template>
				
<xsl:template match='e:entity' mode="generate-mssql-create-sql">
	<xsl:variable name="name">
		<xsl:choose>
			<xsl:when test="@name"><xsl:value-of select="@name"/></xsl:when>
			<xsl:otherwise><xsl:message terminate = "yes">Entity name is required</xsl:message></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
IF OBJECT_ID('<xsl:value-of select="$name"/>','U') IS NULL
	BEGIN
		CREATE TABLE <xsl:value-of select="$name"/> (
			<xsl:for-each select="e:field">
				<xsl:if test="position()!=1">,</xsl:if>
				<xsl:variable name="fldSql">
					<xsl:apply-templates select="." mode="generate-mssql-create-sql"/>
				</xsl:variable>
				<xsl:value-of select="normalize-space($fldSql)"/>
			</xsl:for-each>
			<xsl:variable name="pkNames">
				<xsl:for-each select="e:field[@pk='true']">
					<xsl:if test="position()!=1">,</xsl:if><xsl:value-of select="@name"/>
				</xsl:for-each>
			</xsl:variable>
			<xsl:if test="count(e:field)>0">,
			CONSTRAINT [<xsl:value-of select="$name"/>_PK] PRIMARY KEY ( <xsl:value-of select="normalize-space($pkNames)"/> )
			</xsl:if>
		)
	END	

<xsl:if test="count(e:field[not(@pk) or @pk='false' or @pk='0'])>0">
IF OBJECT_ID('<xsl:value-of select="$name"/>','U') IS NOT NULL
	BEGIN
		<xsl:for-each select="e:field[not(@pk) or @pk='false' or @pk='0']">
			<xsl:variable name="fldSql">
				<xsl:apply-templates select="." mode="generate-mssql-create-sql"/>
			</xsl:variable>
			IF COL_LENGTH('<xsl:value-of select="$name"/>', '<xsl:value-of select="@name"/>') IS NULL
				BEGIN
					ALTER TABLE <xsl:value-of select="$name"/> ADD <xsl:value-of select="normalize-space($fldSql)"/>
				END
		</xsl:for-each>
	END
</xsl:if>
</xsl:template>

<xsl:template match="e:field" mode="generate-mssql-create-sql">
	<xsl:variable name="name">
		<xsl:choose>
			<xsl:when test="@name"><xsl:value-of select="@name"/></xsl:when>
			<xsl:otherwise><xsl:message terminate = "yes">Field name is required</xsl:message></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="maxLength">
		<xsl:choose>
			<xsl:when test="@maxlength"><xsl:value-of select="@maxlength"/></xsl:when>
			<xsl:otherwise>50</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="defaultValue">
		<xsl:choose>
			<xsl:when test="@default='true' and (@type='bool' or @type='boolean')">1</xsl:when>
			<xsl:when test="@default='false' and (@type='bool' or @type='boolean')">0</xsl:when>
			<xsl:when test="@default"><xsl:value-of select="@default"/></xsl:when>
			<xsl:otherwise></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:value-of select="$name"/><xsl:text> </xsl:text>
	<xsl:choose>
		<xsl:when test="@type='string'">nvarchar(<xsl:value-of select="$maxLength"/>)</xsl:when>
		<xsl:when test="@type='text'">ntext</xsl:when>
		<xsl:when test="@type='datetime'">DATETIME</xsl:when>
		<xsl:when test="@type='bool' or @type='boolean'">bit</xsl:when>
		<xsl:when test="@type='int' or @type='integer' or @type='autoincrement'">int</xsl:when>
		<xsl:when test="@type='decimal'">decimal(12,6)</xsl:when>
		<xsl:when test="@type='float'">float</xsl:when>
		<xsl:when test="@type='double'">float</xsl:when>
	</xsl:choose>
	<xsl:text> </xsl:text>
	<xsl:choose>
		<xsl:when test="@nullable='true' or @nullable='1'">NULL</xsl:when>
		<xsl:otherwise>NOT NULL</xsl:otherwise>
	</xsl:choose>
	<xsl:text> </xsl:text>
	<xsl:if test="@type='autoincrement'">IDENTITY(1,1)</xsl:if>
	<xsl:text> </xsl:text>
	<xsl:if test="@default">DEFAULT '<xsl:value-of select="$defaultValue"/>'</xsl:if>
	<xsl:text> </xsl:text>
</xsl:template>

<xsl:template match="e:entity" mode="generate-dataset-xmlschema">
	<xsl:variable name="schemaName" select="@name"/>
	<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">
		<xs:element name="DataSet" msdata:IsDataSet="true">
			<xs:complexType>
				<xs:choice maxOccurs="unbounded">
					<xs:element name="{$schemaName}">
						<xs:complexType>
							<xs:sequence>
								<xsl:apply-templates select="e:field" mode="generate-dataset-xmlschema-field"/>
							</xs:sequence>
						</xs:complexType>
					</xs:element>
				</xs:choice>
			</xs:complexType>
			<xs:unique name="PKConstraint" msdata:PrimaryKey="true">
				<xs:selector xpath=".//{$schemaName}" />
				<xsl:apply-templates select="e:field[@pk='true' or @pk='1']" mode="generate-dataset-xmlschema-pk"/>
			</xs:unique>
		</xs:element>
	</xs:schema>
</xsl:template>

<xsl:template match="e:field" mode="generate-dataset-xmlschema-pk">
	<xs:field xmlns:xs="http://www.w3.org/2001/XMLSchema" xpath="{@name}" />
</xsl:template>

<xsl:template match="e:field" mode="generate-dataset-xmlschema-field">
	<xs:element xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">
		<xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
		<xsl:if test="@nullable='true' or @nullable='1'">
			<xsl:attribute name="minOccurs">0</xsl:attribute>
		</xsl:if>
		<xsl:if test="@default">
			<xsl:attribute name="default"><xsl:value-of select="@default"/></xsl:attribute>
		</xsl:if>
		<xsl:if test="@type='autoincrement'">
			<xsl:attribute name="msdata:AutoIncrement">true</xsl:attribute>
			<xsl:attribute name="msdata:AutoIncrementSeed">0</xsl:attribute>
		</xsl:if>

		<xsl:if test="not( (@type='string' or @type='text') and @maxlength)">
			<xsl:attribute name="type">
				<xsl:choose>
					<xsl:when test="@type='string'">xs:string</xsl:when>
					<xsl:when test="@type='text'">xs:string</xsl:when>
					<xsl:when test="@type='datetime'">xs:dateTime</xsl:when>
					<xsl:when test="@type='bool' or @type='boolean'">xs:boolean</xsl:when>
					<xsl:when test="@type='int' or @type='integer' or @type='autoincrement'">xs:integer</xsl:when>
					<xsl:when test="@type='decimal'">xs:decimal</xsl:when>
					<xsl:when test="@type='float'">xs:float</xsl:when>
					<xsl:when test="@type='double'">xs:double</xsl:when>
				</xsl:choose>			
			</xsl:attribute>
		</xsl:if>
		
		<xsl:if test="(@type='string' or @type='text') and @maxlength">
			<xs:simpleType>
				<xs:restriction base="xs:string">
					<xs:maxLength value="{@maxlength}" />
				</xs:restriction>
			</xs:simpleType>			
		</xsl:if>
		
	</xs:element>
</xsl:template>


<xsl:template match="d:entity-dalc-triggers" mode="db-dalc-trigger">
	<xsl:param name="eventsMediatorName"/>
	<xsl:variable name="dalcModel">
		<xsl:apply-templates select="e:entity" mode="entity-dalc-triggers"/>
	</xsl:variable>
	<xsl:apply-templates select="msxsl:node-set($dalcModel)/node()" mode="db-dalc-trigger">
		<xsl:with-param name="eventsMediatorName" select="$eventsMediatorName"/>
	</xsl:apply-templates>
</xsl:template>

	<xsl:template match="e:entity-dalc-triggers">
	<xsl:apply-templates select="e:entity" mode="entity-dalc-triggers"/>
</xsl:template>

<xsl:template match="e:entity" mode="entity-dalc-triggers">
	<xsl:variable name="sourcename" select="@name"/>
	<!-- lets collect _all_ actions for this entity -->
	<xsl:variable name="actions">
		<xsl:copy-of select=".//e:action[not(@name='saving' or @name='saved')]"/>
		<!-- deal with composite 'saving' -->
		<xsl:if test="not(.//e:action[@name='creating']) and .//e:action[@name='saving']">
			<e:action name="creating"/>
		</xsl:if>
		<xsl:if test="not(.//e:action[@name='updating']) and .//e:action[@name='saving']">
			<e:action name="updating"/>
		</xsl:if>
		<!-- deal with composite 'saved' -->
		<xsl:if test="not(.//e:action[@name='created']) and .//e:action[@name='saved']">
			<e:action name="created"/>
		</xsl:if>
		<xsl:if test="not(.//e:action[@name='updated']) and .//e:action[@name='saved']">
			<e:action name="updated"/>
		</xsl:if>
	</xsl:variable>
	<xsl:variable name="thisEntity" select="."/>

	<xsl:for-each select="msxsl:node-set($actions)/node()">
		<xsl:variable name="actionName" select="@name"/>
		<xsl:variable name="dalcEventName">
			<xsl:choose>
				<xsl:when test="$actionName='creating'">inserting</xsl:when>
				<xsl:when test="$actionName='created'">inserted</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$actionName"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<!-- select distinct actions -->
		<xsl:if test="not(preceding-sibling::action[@name=$actionName])">
			<d:datarow event="{$dalcEventName}" sourcename="{$sourcename}">
				<r:chain>
					<!-- field triggers -->
					<xsl:for-each select="$thisEntity/e:field">
						<xsl:apply-templates select="e:action[@name=$actionName]/e:*" mode="entity-action-dalc-trigger-execute">
							<xsl:with-param name="field" select="."/>
						</xsl:apply-templates>
						<!-- deal with composite actions -->
						<xsl:if test="$actionName='inserting' or $actionName='updating'">
							<xsl:apply-templates select="e:action[@name='saving']/e:*" mode="entity-action-dalc-trigger-execute">
								<xsl:with-param name="field" select="."/>
							</xsl:apply-templates>							
						</xsl:if>
						<xsl:if test="$actionName='inserted' or $actionName='updated'">
							<xsl:apply-templates select="e:action[@name='saved']/e:*" mode="entity-action-dalc-trigger-execute">
								<xsl:with-param name="field" select="."/>
							</xsl:apply-templates>
						</xsl:if>
					</xsl:for-each>
				</r:chain>
			</d:datarow>
		</xsl:if>
	</xsl:for-each>
</xsl:template>

<xsl:template match="e:set-datetimenow" mode="entity-action-dalc-trigger-execute">
	<xsl:param name="field"/>
	<r:execute>
		<r:target>
			<r:invoke-operation method="set_Item">
				<r:target>
					<r:linq>var["row"]</r:linq>
				</r:target>
				<r:args>
					<r:const value="{$field/@name}"/>
					<r:ognl>@DateTime@Now</r:ognl>
				</r:args>
			</r:invoke-operation>
		</r:target>
	</r:execute>
</xsl:template>

<xsl:template match="e:set-identity" mode="entity-action-dalc-trigger-execute">
	<xsl:param name="field"/>
	<r:execute>
		<r:target>
			<r:invoke-operation method="set_Item">
				<r:target>
					<r:linq>var["row"]</r:linq>
				</r:target>
				<r:args>
					<r:const value="{$field/@name}"/>
					<r:ognl>@System.Threading.Thread@CurrentPrincipal.Identity.Name</r:ognl>
				</r:args>
			</r:invoke-operation>
		</r:target>
	</r:execute>
</xsl:template>				

<xsl:template match="e:set-userkey" mode="entity-action-dalc-trigger-execute">
	<xsl:param name="field"/>
	<r:execute>
		<r:target>
			<r:invoke-operation method="set_Item">
				<r:target>
					<r:linq>var["row"]</r:linq>
				</r:target>
				<r:args>
					<r:const value="{$field/@name}"/>
					<r:ognl>#user = @System.Web.Security.Membership@GetUser(), #user!=null ? #user.ProviderUserKey : null</r:ognl>
				</r:args>
			</r:invoke-operation>
		</r:target>
	</r:execute>
</xsl:template>	

</xsl:stylesheet>
