#!/usr/bin/env python3
"""
Generate all 5 CMDT objects, fields, and seed records for AIRFX deep CMDT build.
All records seeded with Active__c = false.
"""

import os

BASE = "/Users/rsmith2/utopia-project/force-app/main/default"
OBJECTS_DIR = os.path.join(BASE, "objects")
CMDT_DIR = os.path.join(BASE, "customMetadata")

TODAY = "2026-03-07"

# ============================================================
# XML Templates
# ============================================================

OBJECT_XML = """<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>{label}</label>
    <pluralLabel>{plural}</pluralLabel>
    <visibility>Public</visibility>
</CustomObject>
"""

FIELD_XML_TEXT = """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>{name}</fullName>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <label>{label}</label>
    <length>{length}</length>
    <type>Text</type>
</CustomField>
"""

FIELD_XML_TEXTAREA = """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>{name}</fullName>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <label>{label}</label>
    <length>{length}</length>
    <type>LongTextArea</type>
    <visibleLines>3</visibleLines>
</CustomField>
"""

FIELD_XML_CHECKBOX = """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>{name}</fullName>
    <defaultValue>false</defaultValue>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <label>{label}</label>
    <type>Checkbox</type>
</CustomField>
"""

FIELD_XML_DATE = """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>{name}</fullName>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <label>{label}</label>
    <type>Date</type>
</CustomField>
"""

FIELD_XML_PICKLIST = """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>{name}</fullName>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <label>{label}</label>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
{values}
        </valueSetDefinition>
    </valueSet>
</CustomField>
"""

def picklist_value(val, default=False):
    d = f"\n                <default>{str(default).lower()}</default>" if default else "\n                <default>false</default>"
    return f"""            <value>
                <fullName>{val}</fullName>{d}
                <label>{val}</label>
            </value>"""


# ============================================================
# Helpers
# ============================================================

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content.strip() + '\n')

def create_object(api_name, label, plural):
    obj_dir = os.path.join(OBJECTS_DIR, api_name)
    write_file(os.path.join(obj_dir, f"{api_name}.object-meta.xml"),
               OBJECT_XML.format(label=label, plural=plural))
    return obj_dir

def create_field(obj_dir, field_name, label, field_type, **kwargs):
    fields_dir = os.path.join(obj_dir, "fields")
    if field_type == 'Text':
        xml = FIELD_XML_TEXT.format(name=field_name, label=label, length=kwargs.get('length', 255))
    elif field_type == 'LongTextArea':
        xml = FIELD_XML_TEXTAREA.format(name=field_name, label=label, length=kwargs.get('length', 32000))
    elif field_type == 'Checkbox':
        xml = FIELD_XML_CHECKBOX.format(name=field_name, label=label)
    elif field_type == 'Date':
        xml = FIELD_XML_DATE.format(name=field_name, label=label)
    elif field_type == 'Picklist':
        values = '\n'.join([picklist_value(v) for v in kwargs['values']])
        xml = FIELD_XML_PICKLIST.format(name=field_name, label=label, values=values)
    write_file(os.path.join(fields_dir, f"{field_name}.field-meta.xml"), xml)

def xml_escape(s):
    if s is None:
        return ''
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')

def create_record(cmdt_api_name, record_name, label, fields):
    """
    fields: list of (field_api_name, xsi_type, value)
    xsi_type: 'xsd:string', 'xsd:boolean', 'xsd:date'
    """
    values_xml = ""
    for fname, xsi_type, val in fields:
        if val is None:
            values_xml += f"""
    <values>
        <field>{fname}</field>
        <value xsi:nil="true"/>
    </values>"""
        else:
            escaped_val = xml_escape(str(val)) if xsi_type == 'xsd:string' else str(val).lower() if xsi_type == 'xsd:boolean' else str(val)
            values_xml += f"""
    <values>
        <field>{fname}</field>
        <value xsi:type="{xsi_type}">{escaped_val}</value>
    </values>"""

    xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>{xml_escape(label)}</label>
    <protected>false</protected>{values_xml}
</CustomMetadata>"""

    write_file(os.path.join(CMDT_DIR, f"{cmdt_api_name}.{record_name}.md-meta.xml"), xml)


# ============================================================
# Common fields for all 5 objects
# ============================================================

def add_common_fields(obj_dir):
    create_field(obj_dir, "Active__c", "Active", "Checkbox")
    create_field(obj_dir, "Source_Doc__c", "Source Document", "Text", length=255)
    create_field(obj_dir, "Source_Date__c", "Source Date", "Date")
    create_field(obj_dir, "Confidence__c", "Confidence", "Picklist",
                 values=["VERIFIED", "INFERRED", "NEEDS_REVIEW"])
    create_field(obj_dir, "Notes__c", "Notes", "LongTextArea", length=32000)

def common_fields(active, source_doc, source_date, confidence, notes):
    return [
        ("Active__c", "xsd:boolean", active),
        ("Source_Doc__c", "xsd:string", source_doc),
        ("Source_Date__c", "xsd:date", source_date),
        ("Confidence__c", "xsd:string", confidence),
        ("Notes__c", "xsd:string", notes),
    ]


# ============================================================
# Object 1: Hyperforce_Region__mdt
# ============================================================

def build_hyperforce_region():
    obj_dir = create_object("Hyperforce_Region__mdt", "Hyperforce Region", "Hyperforce Regions")
    add_common_fields(obj_dir)
    create_field(obj_dir, "Country_Code__c", "Country Code", "Text", length=10)
    create_field(obj_dir, "Country_Name__c", "Country Name", "Text", length=100)
    create_field(obj_dir, "Available__c", "Available", "Checkbox")
    create_field(obj_dir, "AWS_Region__c", "AWS Region", "Text", length=100)

    CDN_CAVEAT = "Akamai, CloudFront, Cloudflare, Fastly CDN routes globally regardless of org region. Data may transit any country."
    SOURCE = "Salesforce Infrastructure & Sub-processors March 2026"

    # VERIFIED Hyperforce regions
    hyperforce_regions = {
        "AU": ("Australia", "ap-southeast-2"),
        "BR": ("Brazil", "sa-east-1"),
        "CA": ("Canada", "ca-central-1"),
        "DE": ("Germany", "eu-central-1"),
        "FR": ("France", "eu-west-3"),
        "GB": ("United Kingdom", "eu-west-2"),
        "ID": ("Indonesia", "ap-southeast-3"),
        "IE": ("Ireland", "eu-west-1"),
        "IL": ("Israel", "il-central-1"),
        "IN": ("India", "ap-south-1"),
        "IT": ("Italy", "eu-south-1"),
        "JP": ("Japan", "ap-northeast-1"),
        "KR": ("South Korea", "ap-northeast-2"),
        "SE": ("Sweden", "eu-north-1"),
        "SG": ("Singapore", "ap-southeast-1"),
        "CH": ("Switzerland", "eu-central-2"),
        "AE": ("UAE", "me-south-1"),
        "US": ("United States", "us-east-1"),
    }

    for code, (name, aws) in hyperforce_regions.items():
        fields = common_fields(False, SOURCE, TODAY, "VERIFIED",
                               f"{CDN_CAVEAT}")
        fields += [
            ("Country_Code__c", "xsd:string", code),
            ("Country_Name__c", "xsd:string", name),
            ("Available__c", "xsd:boolean", True),
            ("AWS_Region__c", "xsd:string", aws),
        ]
        create_record("Hyperforce_Region__mdt", f"HF_{code}", f"Hyperforce {name}", fields)

    # NOT in Hyperforce
    not_hyperforce = {
        "NO": "Norway", "NL": "Netherlands", "BE": "Belgium",
        "DK": "Denmark", "FI": "Finland", "ZA": "South Africa",
        "PL": "Poland", "CN": "China", "MX": "Mexico",
        "AR": "Argentina", "EG": "Egypt", "NZ": "New Zealand",
        "RU": "Russia",
    }

    for code, name in not_hyperforce.items():
        fields = common_fields(False, SOURCE, TODAY, "VERIFIED",
                               f"Not available in Hyperforce as of March 2026. {CDN_CAVEAT}")
        fields += [
            ("Country_Code__c", "xsd:string", code),
            ("Country_Name__c", "xsd:string", name),
            ("Available__c", "xsd:boolean", False),
            ("AWS_Region__c", "xsd:string", None),
        ]
        create_record("Hyperforce_Region__mdt", f"HF_{code}", f"Hyperforce {name}", fields)

    print(f"  Hyperforce_Region__mdt: {len(hyperforce_regions) + len(not_hyperforce)} records")


# ============================================================
# Object 2: Product_Region__mdt
# ============================================================

def build_product_region():
    obj_dir = create_object("Product_Region__mdt", "Product Region", "Product Regions")
    add_common_fields(obj_dir)
    create_field(obj_dir, "Product__c", "Product", "Picklist",
                 values=["CORE", "MARKETING_CLOUD", "DATA_CLOUD", "MULESOFT",
                          "TABLEAU", "SLACK", "GOVCLOUD", "AGENTFORCE"])
    create_field(obj_dir, "Country_Code__c", "Country Code", "Text", length=10)
    create_field(obj_dir, "Available__c", "Available", "Checkbox")
    create_field(obj_dir, "Caveat__c", "Caveat", "LongTextArea", length=32000)

    ALL_COUNTRIES = ["AU", "BR", "CA", "DE", "FR", "GB", "ID", "IE", "IL",
                     "IN", "IT", "JP", "KR", "SE", "SG", "CH", "AE", "US"]

    record_count = 0

    # MARKETING_CLOUD
    mc_verified = {
        "AU": ("Hyperforce since Dec 11 2023", "salesforce.com/au/blog December 2023"),
        "JP": ("Hyperforce available", "Salesforce Infrastructure & Sub-processors March 2026"),
        "IN": ("Hyperforce available", "Salesforce Infrastructure & Sub-processors March 2026"),
    }
    mc_inferred = {
        "US": ("Roadmapped 2026", "Salesforce product roadmap"),
    }

    for code, (caveat, source) in mc_verified.items():
        fields = common_fields(False, source, TODAY, "VERIFIED", caveat)
        fields += [
            ("Product__c", "xsd:string", "MARKETING_CLOUD"),
            ("Country_Code__c", "xsd:string", code),
            ("Available__c", "xsd:boolean", True),
            ("Caveat__c", "xsd:string", caveat),
        ]
        create_record("Product_Region__mdt", f"MC_{code}", f"Marketing Cloud {code}", fields)
        record_count += 1

    for code, (caveat, source) in mc_inferred.items():
        fields = common_fields(False, source, TODAY, "INFERRED", caveat)
        fields += [
            ("Product__c", "xsd:string", "MARKETING_CLOUD"),
            ("Country_Code__c", "xsd:string", code),
            ("Available__c", "xsd:boolean", True),
            ("Caveat__c", "xsd:string", caveat),
        ]
        create_record("Product_Region__mdt", f"MC_{code}", f"Marketing Cloud {code}", fields)
        record_count += 1

    for code in ALL_COUNTRIES:
        if code not in mc_verified and code not in mc_inferred:
            fields = common_fields(False, "Salesforce Infrastructure & Sub-processors March 2026", TODAY,
                                   "NEEDS_REVIEW", "Marketing Cloud Hyperforce availability unconfirmed for this region")
            fields += [
                ("Product__c", "xsd:string", "MARKETING_CLOUD"),
                ("Country_Code__c", "xsd:string", code),
                ("Available__c", "xsd:boolean", False),
                ("Caveat__c", "xsd:string", "Hyperforce availability unconfirmed for this region"),
            ]
            create_record("Product_Region__mdt", f"MC_{code}", f"Marketing Cloud {code}", fields)
            record_count += 1

    # DATA_CLOUD
    dc_verified = {"AU", "JP", "IN"}
    for code in ALL_COUNTRIES:
        if code in dc_verified:
            fields = common_fields(False, "salesforce.com/au/blog December 2023", TODAY, "VERIFIED",
                                   "Hyperforce since Dec 11 2023")
            fields += [
                ("Product__c", "xsd:string", "DATA_CLOUD"),
                ("Country_Code__c", "xsd:string", code),
                ("Available__c", "xsd:boolean", True),
                ("Caveat__c", "xsd:string", "Hyperforce since Dec 11 2023"),
            ]
        else:
            fields = common_fields(False, "Salesforce Infrastructure & Sub-processors March 2026", TODAY,
                                   "NEEDS_REVIEW", "Data Cloud Hyperforce availability unconfirmed for this region")
            fields += [
                ("Product__c", "xsd:string", "DATA_CLOUD"),
                ("Country_Code__c", "xsd:string", code),
                ("Available__c", "xsd:boolean", False),
                ("Caveat__c", "xsd:string", "Hyperforce availability unconfirmed for this region"),
            ]
        create_record("Product_Region__mdt", f"DC_{code}", f"Data Cloud {code}", fields)
        record_count += 1

    # GOVCLOUD - US only
    fields = common_fields(False, "salesforce.com/government/cloud", TODAY, "VERIFIED",
                           "AWS GovCloud US only. FedRAMP High (Gov Cloud Plus). DoD IL4/IL5 (Gov Cloud Plus Defense).")
    fields += [
        ("Product__c", "xsd:string", "GOVCLOUD"),
        ("Country_Code__c", "xsd:string", "US"),
        ("Available__c", "xsd:boolean", True),
        ("Caveat__c", "xsd:string", "AWS GovCloud US only. FedRAMP High (Gov Cloud Plus). DoD IL4/IL5 (Gov Cloud Plus Defense)."),
    ]
    create_record("Product_Region__mdt", "GC_US", "GovCloud US", fields)
    record_count += 1

    for code in ALL_COUNTRIES:
        if code != "US":
            fields = common_fields(False, "salesforce.com/government/cloud", TODAY, "VERIFIED",
                                   "GovCloud is US-only. Not available outside United States.")
            fields += [
                ("Product__c", "xsd:string", "GOVCLOUD"),
                ("Country_Code__c", "xsd:string", code),
                ("Available__c", "xsd:boolean", False),
                ("Caveat__c", "xsd:string", "GovCloud is US-only. Not available outside United States."),
            ]
            create_record("Product_Region__mdt", f"GC_{code}", f"GovCloud {code}", fields)
            record_count += 1

    # MULESOFT - US federal only
    fields = common_fields(False, "compliance.salesforce.com", TODAY, "VERIFIED",
                           "FedRAMP Moderate. AWS GovCloud. US federal only.")
    fields += [
        ("Product__c", "xsd:string", "MULESOFT"),
        ("Country_Code__c", "xsd:string", "US"),
        ("Available__c", "xsd:boolean", True),
        ("Caveat__c", "xsd:string", "FedRAMP Moderate. AWS GovCloud. US federal only."),
    ]
    create_record("Product_Region__mdt", "MS_US", "MuleSoft US", fields)
    record_count += 1

    for code in ALL_COUNTRIES:
        if code != "US":
            fields = common_fields(False, "compliance.salesforce.com", TODAY, "INFERRED",
                                   "MuleSoft Gov Cloud is US federal only. Commercial MuleSoft Hyperforce availability varies.")
            fields += [
                ("Product__c", "xsd:string", "MULESOFT"),
                ("Country_Code__c", "xsd:string", code),
                ("Available__c", "xsd:boolean", False),
                ("Caveat__c", "xsd:string", "MuleSoft Gov Cloud is US federal only. Commercial MuleSoft Hyperforce availability varies."),
            ]
            create_record("Product_Region__mdt", f"MS_{code}", f"MuleSoft {code}", fields)
            record_count += 1

    # TABLEAU - all NEEDS_REVIEW
    for code in ALL_COUNTRIES:
        fields = common_fields(False, "Salesforce product roadmap", TODAY, "NEEDS_REVIEW",
                               "Tableau Next FedRAMP High Jun 2025. Hyperforce region availability unconfirmed.")
        fields += [
            ("Product__c", "xsd:string", "TABLEAU"),
            ("Country_Code__c", "xsd:string", code),
            ("Available__c", "xsd:boolean", False),
            ("Caveat__c", "xsd:string", "Tableau Next FedRAMP High Jun 2025. Hyperforce region availability unconfirmed."),
        ]
        create_record("Product_Region__mdt", f"TB_{code}", f"Tableau {code}", fields)
        record_count += 1

    # SLACK/GOVSLACK - US verified, others NEEDS_REVIEW
    fields = common_fields(False, "salesforce.com/news/stories/fedramp-certified-platforms", TODAY, "VERIFIED",
                           "GovSlack FedRAMP High JAB authorized")
    fields += [
        ("Product__c", "xsd:string", "SLACK"),
        ("Country_Code__c", "xsd:string", "US"),
        ("Available__c", "xsd:boolean", True),
        ("Caveat__c", "xsd:string", "GovSlack FedRAMP High JAB authorized"),
    ]
    create_record("Product_Region__mdt", "SL_US", "Slack US", fields)
    record_count += 1

    for code in ALL_COUNTRIES:
        if code != "US":
            fields = common_fields(False, "salesforce.com/news/stories/fedramp-certified-platforms", TODAY,
                                   "NEEDS_REVIEW", "Slack/GovSlack availability outside US unconfirmed")
            fields += [
                ("Product__c", "xsd:string", "SLACK"),
                ("Country_Code__c", "xsd:string", code),
                ("Available__c", "xsd:boolean", False),
                ("Caveat__c", "xsd:string", "Slack/GovSlack availability outside US unconfirmed"),
            ]
            create_record("Product_Region__mdt", f"SL_{code}", f"Slack {code}", fields)
            record_count += 1

    # AGENTFORCE - US verified, others NEEDS_REVIEW
    fields = common_fields(False, "salesforce.com/news/stories/fedramp-high-agentforce", TODAY, "VERIFIED",
                           "FedRAMP High authorized June 2025")
    fields += [
        ("Product__c", "xsd:string", "AGENTFORCE"),
        ("Country_Code__c", "xsd:string", "US"),
        ("Available__c", "xsd:boolean", True),
        ("Caveat__c", "xsd:string", "FedRAMP High authorized June 2025"),
    ]
    create_record("Product_Region__mdt", "AF_US", "Agentforce US", fields)
    record_count += 1

    for code in ALL_COUNTRIES:
        if code != "US":
            fields = common_fields(False, "salesforce.com/news/stories/fedramp-high-agentforce", TODAY,
                                   "NEEDS_REVIEW", "Agentforce availability outside US unconfirmed")
            fields += [
                ("Product__c", "xsd:string", "AGENTFORCE"),
                ("Country_Code__c", "xsd:string", code),
                ("Available__c", "xsd:boolean", False),
                ("Caveat__c", "xsd:string", "Agentforce availability outside US unconfirmed"),
            ]
            create_record("Product_Region__mdt", f"AF_{code}", f"Agentforce {code}", fields)
            record_count += 1

    print(f"  Product_Region__mdt: {record_count} records")


# ============================================================
# Object 3: Certification__mdt
# ============================================================

def build_certification():
    obj_dir = create_object("Certification__mdt", "Certification", "Certifications")
    add_common_fields(obj_dir)
    create_field(obj_dir, "Product__c", "Product", "Text", length=100)
    create_field(obj_dir, "Certification__c", "Certification", "Text", length=100)
    create_field(obj_dir, "Level__c", "Level", "Text", length=100)
    create_field(obj_dir, "Status__c", "Status", "Picklist",
                 values=["CURRENT", "PENDING", "NOT_APPLICABLE"])
    create_field(obj_dir, "Scope_Notes__c", "Scope Notes", "LongTextArea", length=32000)
    create_field(obj_dir, "Authorized_Since__c", "Authorized Since", "Text", length=50)

    certs = [
        ("GovCloudPlus_FedRAMP", "Gov Cloud Plus FedRAMP High",
         "Gov Cloud Plus", "FedRAMP High", "High", "CURRENT",
         "JAB P-ATO May 2020. DoD IL4 reciprocity.",
         "May 2020", "compliance.salesforce.com", "VERIFIED"),
        ("Agentforce_FedRAMP", "Agentforce FedRAMP High",
         "Agentforce", "FedRAMP High", "High", "CURRENT",
         "Authorized June 2025",
         "June 2025", "salesforce.com news June 2025", "VERIFIED"),
        ("DataCloud_FedRAMP", "Data Cloud FedRAMP High",
         "Data Cloud", "FedRAMP High", "High", "CURRENT",
         "Authorized June 2025",
         "June 2025", "salesforce.com news June 2025", "VERIFIED"),
        ("MarketingCloud_FedRAMP", "Marketing Cloud FedRAMP High",
         "Marketing Cloud", "FedRAMP High", "High", "CURRENT",
         "Authorized June 2025",
         "June 2025", "salesforce.com news June 2025", "VERIFIED"),
        ("TableauNext_FedRAMP", "Tableau Next FedRAMP High",
         "Tableau Next", "FedRAMP High", "High", "CURRENT",
         "Authorized June 2025",
         "June 2025", "salesforce.com news June 2025", "VERIFIED"),
        ("GovSlack_FedRAMP", "GovSlack FedRAMP High",
         "GovSlack", "FedRAMP High", "High", "CURRENT",
         "JAB authorized",
         None, "salesforce.com/news/stories/fedramp-certified-platforms", "VERIFIED"),
        ("ServiceCloudVoice_FedRAMP", "Service Cloud Voice FedRAMP High",
         "Service Cloud Voice", "FedRAMP High", "High", "CURRENT",
         "Authorized June 2025",
         "June 2025", "salesforce.com news June 2025", "VERIFIED"),
        ("MuleSoft_FedRAMP", "MuleSoft Gov Cloud FedRAMP Moderate",
         "MuleSoft Gov Cloud", "FedRAMP Moderate", "Moderate", "CURRENT",
         "Agency-sponsored ATO. US federal only.",
         None, "compliance.salesforce.com", "VERIFIED"),
        ("GovCloud_FedRAMP_Mod", "Gov Cloud FedRAMP Moderate",
         "Gov Cloud", "FedRAMP Moderate", "Moderate", "CURRENT",
         "Standard Gov Cloud FedRAMP Moderate authorization.",
         None, "compliance.salesforce.com", "VERIFIED"),
        ("Core_ISO27001", "Salesforce Core ISO 27001:2022",
         "Salesforce Core", "ISO 27001:2022", None, "CURRENT",
         "2013 superseded. Current cert is 2022.",
         None, "compliance.salesforce.com", "VERIFIED"),
        ("Core_ISMAP", "Core Platform ISMAP",
         "Core Platform", "ISMAP", None, "CURRENT",
         "Japan ISMAP certification current.",
         None, "compliance.salesforce.com", "VERIFIED"),
        ("MuleSoft_ISMAP", "MuleSoft on Hyperforce ISMAP",
         "MuleSoft on Hyperforce", "ISMAP", None, "CURRENT",
         "MuleSoft on Hyperforce ISMAP certified.",
         None, "compliance.salesforce.com", "VERIFIED"),
        ("Tableau_ISMAP", "Tableau Cloud on Hyperforce ISMAP",
         "Tableau Cloud on Hyperforce", "ISMAP", None, "CURRENT",
         "Tableau Cloud on Hyperforce ISMAP certified.",
         None, "compliance.salesforce.com", "VERIFIED"),
    ]

    for (rec_name, label, product, cert, level, status, scope, auth_since, source, confidence) in certs:
        flds = common_fields(False, source, TODAY, confidence, scope)
        flds += [
            ("Product__c", "xsd:string", product),
            ("Certification__c", "xsd:string", cert),
            ("Level__c", "xsd:string", level),
            ("Status__c", "xsd:string", status),
            ("Scope_Notes__c", "xsd:string", scope),
            ("Authorized_Since__c", "xsd:string", auth_since),
        ]
        create_record("Certification__mdt", rec_name, label, flds)

    print(f"  Certification__mdt: {len(certs)} records")


# ============================================================
# Object 4: Feature_Availability__mdt
# ============================================================

def build_feature_availability():
    obj_dir = create_object("Feature_Availability__mdt", "Feature Availability", "Feature Availabilities")
    add_common_fields(obj_dir)
    create_field(obj_dir, "Feature__c", "Feature", "Text", length=255)
    create_field(obj_dir, "Included_In_Base__c", "Included In Base", "Checkbox")
    create_field(obj_dir, "Add_On_Name__c", "Add-On Name", "Text", length=255)
    create_field(obj_dir, "Pricing_Note__c", "Pricing Note", "Text", length=255)
    create_field(obj_dir, "Limitations__c", "Limitations", "LongTextArea", length=32000)

    SOURCE = "salesforce.com/platform/shield"

    features = [
        ("Shield_Encryption", "Shield Platform Encryption",
         "Shield Platform Encryption", False, "Salesforce Shield",
         "~20% of total Salesforce spend",
         "Does not cover Einstein AI, Marketing Cloud, or Quip. Not all fields supported."),
        ("Shield_Event_Monitoring", "Shield Event Monitoring",
         "Shield Event Monitoring", False, "Salesforce Shield",
         "~10% of total Salesforce spend",
         "Event logs retained 30 days by default. Basic Core Event Monitoring IS included in base."),
        ("Shield_Field_Audit_Trail", "Shield Field Audit Trail",
         "Shield Field Audit Trail", False, "Salesforce Shield",
         "~10% of total Salesforce spend",
         "Extends to 10 years. Up to 60 fields/object. Standard 18-24mo tracking IS included in base."),
        ("Shield_Full_Bundle", "Shield Full Bundle",
         "Shield Full Bundle", False, "Salesforce Shield",
         "~30% of total Salesforce spend",
         "Includes Platform Encryption, Event Monitoring, and Field Audit Trail."),
        ("BYOK", "Bring Your Own Key",
         "BYOK (Bring Your Own Key)", False, "Shield Platform Encryption",
         None,
         "Requires Shield. Supports AWS KMS."),
        ("EU_Operating_Zone", "EU Operating Zone",
         "EU Operating Zone", False, "Hyperforce EU Operating Zone",
         None,
         "Paid upgrade. EU-based support + data isolation to EU boundary."),
        ("GovCloud_Plus", "Government Cloud Plus",
         "Government Cloud Plus", False, "Separate SKU",
         None,
         "US only. FedRAMP High. Plus Defense adds IL4/IL5."),
        ("Premier_Support", "Premier Support / Signature Success",
         "Premier Support / Signature Success", False, None,
         "Negotiated - contact AE",
         "Premier and Signature tiers available. Pricing negotiated per deal."),
    ]

    for (rec_name, label, feature, included, addon, pricing, limitations) in features:
        source = SOURCE
        if rec_name == "EU_Operating_Zone":
            source = "salesforce.com/platform/data-residence-eu-oz"
        flds = common_fields(False, source, TODAY, "VERIFIED", limitations)
        flds += [
            ("Feature__c", "xsd:string", feature),
            ("Included_In_Base__c", "xsd:boolean", included),
            ("Add_On_Name__c", "xsd:string", addon),
            ("Pricing_Note__c", "xsd:string", pricing),
            ("Limitations__c", "xsd:string", limitations),
        ]
        create_record("Feature_Availability__mdt", rec_name, label, flds)

    print(f"  Feature_Availability__mdt: {len(features)} records")


# ============================================================
# Object 5: Hard_No__mdt
# ============================================================

def build_hard_no():
    obj_dir = create_object("Hard_No__mdt", "Hard No", "Hard Nos")
    add_common_fields(obj_dir)
    create_field(obj_dir, "Label__c", "Label", "Text", length=255)
    create_field(obj_dir, "Keywords__c", "Keywords", "LongTextArea", length=32000)
    create_field(obj_dir, "Reason__c", "Reason", "LongTextArea", length=32000)
    create_field(obj_dir, "Negotiable__c", "Negotiable", "Checkbox")
    create_field(obj_dir, "Recommended_Response__c", "Recommended Response", "LongTextArea", length=32000)

    hard_nos = [
        ("Dedicated_Hardware", "Dedicated Hardware",
         "dedicated hardware, dedicated server, sole-tenant",
         "Salesforce is a multi-tenant SaaS platform. Dedicated hardware is not available.",
         "Salesforce operates on a shared, multi-tenant infrastructure with logical data separation. Hyperforce provides regional data residency but not dedicated hardware."),
        ("On_Premises", "On-Premises",
         "on-premises, on-premise, on-prem, self-hosted",
         "Cloud-only except MuleSoft Runtime and Tableau Desktop",
         "Salesforce is cloud-only. MuleSoft Anypoint Runtime can be deployed on-premises. Tableau Desktop is a local application. All other products are SaaS-only."),
        ("Source_Code_Escrow", "Source Code Escrow",
         "source code escrow, code escrow",
         "Salesforce does not offer source code escrow agreements.",
         "As a multi-tenant SaaS provider, Salesforce does not provide source code escrow. Service continuity is ensured through SLA commitments and data export capabilities."),
        ("IL6_Classified", "IL6 / Classified Data",
         "IL6, impact level 6, classified data, top secret",
         "Max is IL5/Top Secret unclassified",
         "Salesforce Gov Cloud Plus Defense supports up to DoD IL5 (Top Secret Unclassified). IL6 (classified/secret) workloads are not supported."),
        ("Customer_VMs", "Customer VMs",
         "customer VM, customer virtual machine, bring your own VM",
         "Salesforce does not support customer-provisioned virtual machines.",
         "Salesforce is a fully managed SaaS platform. Customers cannot provision or manage their own VMs within the Salesforce infrastructure."),
        ("Customer_NDA", "Customer-Specific NDA",
         "customer-specific NDA, custom NDA, bilateral NDA",
         "Salesforce uses standard contractual terms. Custom NDAs are not available.",
         "Salesforce operates under its Master Subscription Agreement and Trust & Compliance documentation. Customer-specific NDAs are not part of the standard engagement model."),
        ("SBOM", "Software Bill of Materials",
         "software bill of materials, SBOM",
         "Salesforce does not provide an SBOM to customers.",
         "Salesforce does not share its Software Bill of Materials. Security is maintained through internal vulnerability management, penetration testing, and third-party audits."),
        ("SecNumCloud", "SecNumCloud",
         "secnumcloud, SecNumCloud",
         "French ANSSI cert. Not held.",
         "Salesforce does not hold SecNumCloud certification from ANSSI (French National Cybersecurity Agency). EU data residency is available via Hyperforce EU regions."),
        ("IPv6", "IPv6",
         "IPv6",
         "Not supported",
         "Salesforce infrastructure operates on IPv4. IPv6 is not currently supported for Salesforce services."),
        ("ISO_20000", "ISO 20000",
         "ISO 20000, ISO/IEC 20000",
         "Not held",
         "Salesforce does not hold ISO 20000 (IT Service Management) certification. ITIL-aligned service management practices are followed."),
        ("ISO_14001", "ISO 14001",
         "ISO 14001",
         "Not held",
         "Salesforce does not hold ISO 14001 (Environmental Management) certification. Sustainability commitments are documented at salesforce.com/sustainability."),
        ("ISO_45001", "ISO 45001",
         "ISO 45001",
         "Not held",
         "Salesforce does not hold ISO 45001 (Occupational Health & Safety) certification."),
        ("Defer_Upgrades", "Defer Upgrades",
         "defer upgrade, delay upgrade, opt out of upgrade",
         "3 releases/year, cannot defer",
         "Salesforce delivers 3 major releases per year (Spring, Summer, Winter). Customers cannot defer or opt out of platform upgrades. Sandbox preview is available before production release."),
        ("Customer_Approval_Changes", "Customer Approval Before Changes",
         "customer approval before changes, approve changes before",
         "Salesforce does not require customer approval before platform changes.",
         "Salesforce provides advance notice of changes via Release Notes and Trust notifications. Customers cannot block or approve changes to the shared platform."),
        ("Encryption_In_Memory", "Encryption In Memory",
         "encrypt in memory, in-memory encryption",
         "Salesforce does not encrypt data in memory.",
         "Salesforce encrypts data at rest (AES-256) and in transit (TLS 1.2+). In-memory encryption is not provided due to the nature of multi-tenant application processing."),
        ("FIPS_140_3", "FIPS 140-3",
         "FIPS 140-3",
         "FIPS 140-2 supported. 140-3 is not.",
         "Salesforce Gov Cloud Plus uses FIPS 140-2 validated cryptographic modules. FIPS 140-3 validation is not yet available."),
        ("IPS", "Intrusion Prevention System",
         "intrusion prevention system, IPS",
         "Salesforce uses IDS not IPS",
         "Salesforce employs Intrusion Detection Systems (IDS) for monitoring. Intrusion Prevention Systems (IPS) are not deployed in the traditional sense; mitigation is handled through WAF, DDoS protection, and security operations."),
    ]

    for (rec_name, label, keywords, reason, response) in hard_nos:
        flds = common_fields(False, "Salesforce Trust & Compliance documentation", TODAY, "VERIFIED", reason)
        flds += [
            ("Label__c", "xsd:string", label),
            ("Keywords__c", "xsd:string", keywords),
            ("Reason__c", "xsd:string", reason),
            ("Negotiable__c", "xsd:boolean", False),
            ("Recommended_Response__c", "xsd:string", response),
        ]
        create_record("Hard_No__mdt", rec_name, label, flds)

    print(f"  Hard_No__mdt: {len(hard_nos)} records")


# ============================================================
# Main
# ============================================================

if __name__ == '__main__':
    print("Generating CMDT metadata files...")
    build_hyperforce_region()
    build_product_region()
    build_certification()
    build_feature_availability()
    build_hard_no()
    print("\nDone. Files written to:")
    print(f"  Objects: {OBJECTS_DIR}")
    print(f"  Records: {CMDT_DIR}")
