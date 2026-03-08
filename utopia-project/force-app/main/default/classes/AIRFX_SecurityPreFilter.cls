public with sharing class AIRFX_SecurityPreFilter {

    public class Result {
        public Boolean skipAsGreen;
        public List<String> matchedFunctionalTerms = new List<String>();
        public List<String> matchedSecurityTerms = new List<String>();
    }

    private static final List<String> FUNCTIONAL_TERMS = new List<String>{'dashboard','dashboards','report','reports','export','exports',
        'workflow','drag-and-drop','onboarding','training','notification',
        'notifications','ui','user interface','mobile-responsive',
        'search','sortable','email template','display preferences',
        'admin console','custom report','bulk update',
        'integration','integrations','documentation','training materials',
        'dashboard layouts','ui customization',
        'manage candidate volunteers','candidate volunteers','volunteers',
        'volunteer management','manage volunteers','candidate management',
        'training pathway','training pathways','formal training','informal training',
        'documentation and resources','training materials','service level agreement',
        'service level agreements','implementation','implementation phase',
        'implementation plan','deployment','deployment solution',
        'standard approach','service and contract management','contract management',
        'charging model','charges','order of magnitude charges',
        'assumptions','risks','caveats','frameworks','procurement partners',
        'user engagement','subject matter experts','clinical teams','service managers',
        'trust effort','trust requirements','multiple organisations',
        'live reporting','reporting functionality','custom trust defined reports',
        'assumptions','risks','caveats','information required','clarifications','details requested','highlight','identify','provide','timescales','deployment','implementation','implementation phase','implementation plan','frameworks','procurement partners','clinical standards','compliance standards','NHS standards','charging model','charges','order of magnitude','service and contract management','user engagement','stakeholders','subject matter experts','service managers','trust obligations','multiple organisations','collaboration','live reporting','reporting functionality','custom trust defined reports','training pathway','training pathways','formal training','informal training','documentation and resources','service level agreement','service level agreements','standard approach','solution overview',
        'assumptions','risks','caveats','information required','clarifications','details requested','highlight','identify','provide','timescales','deployment','implementation','implementation phase','implementation plan','frameworks','procurement partners','clinical standards','compliance standards','NHS standards','charging model','charges','order of magnitude','service and contract management','user engagement','stakeholders','subject matter experts','service managers','trust obligations','multiple organisations','collaboration','live reporting','reporting functionality','custom trust defined reports','training pathway','training pathways','formal training','informal training','documentation and resources','service level agreement','service level agreements','standard approach','solution overview','dashboards','reports','report export','workflow','onboarding','ui','user interface','email template','notifications','drag-and-drop','mobile-responsive','integration','integrations','display preferences','admin console','custom report','bulk update',
        'queue','queues','case assignment','assign case','assign cases','route case','routing case',
        'approval process','knowledge article','knowledge base',
        'mobile app','forecast','pipeline','calendar',
        'field service scheduling','customer portal branding',
        'page layout','screen flow','analytics','visualization','chart',
        'spell check','spellcheck','spell checking',
        'import','bulk import','data import','bulk data import',
        'browser support','mobile support','api support',
        'chat support','customer support','24 7 support',
        'phone support','email support','live support',
        'support team','support staff','support hours'};

    private static final List<String> SECURITY_TERMS = new List<String>{
        'security','secure','privacy','compliance',
        'audit','audit log','audit logs','audit trail',
        'logging','monitoring','incident','breach',
        'encryption','encrypted','mfa','multi-factor',
        'authentication','authorization',
        'access control','access rights','permissions',
        'least privilege','role-based','role based',
        'backup','recovery','disaster recovery',
        'business continuity','availability','uptime',
        'sla','residency','hosted','hosting','region',
        'data center','soc 2','soc2','iso 27001',
        'fedramp','hipaa','nist','cjis',
        'penetration test','vulnerability',
        'background check','customer-managed key',
        'password','password policy','password policies',
        'api security','secure api','security event',
        'escrow','source code','codebase access',
        'sbom','software bill of materials','bill of materials',
        'on-premise','on premise','on-prem','self-hosted',
        'dedicated hardware','dedicated instance','dedicated server','dedicated infrastructure',
        'private cloud',
        'service credit','service credits','liquidated damages',
        'resolution time','remediation','mttr',
        'il4','il5','il6','impact level',
        'ipv6','ip version 6',
        'classified data','classified information','top secret','secret clearance',
        'secnumcloud',
        'virtual machine',
        'defer upgrade','defer upgrades','skip upgrade',
        'data sovereignty','data locality',
        'fips','stateramp','state ramp','cmmc','irs 1075','hecvat',
        'subprocessor','subcontractor',
        'iso 20000','iso 14001','iso 45001',
        'intrusion prevention','ips',
        'scan result','scan report',
        'citizen','citizens','us citizen','us citizens','citizenship',
        'reside','jurisdiction','data must reside'
    };

    public static Result evaluate(String question) {
        Result r = new Result();
        String normalizedQuestion = normalize(question);

        for (String term : FUNCTIONAL_TERMS) {
            if (containsNormalizedTerm(normalizedQuestion, term)) {
                r.matchedFunctionalTerms.add(term);
            }
        }

        for (String term : SECURITY_TERMS) {
            if (containsNormalizedTerm(normalizedQuestion, term)) {
                r.matchedSecurityTerms.add(term);
            }
        }

        if (!r.matchedSecurityTerms.isEmpty()) {
            r.skipAsGreen = false;
        } else if (!r.matchedFunctionalTerms.isEmpty()) {
            r.skipAsGreen = true;
        } else {
            r.skipAsGreen = false;
        }

        return r;
    }

    @TestVisible
    private static String normalize(String input) {
        if (String.isBlank(input)) {
            return '';
        }
        String s = input.toLowerCase();
        s = s.replaceAll('[^a-z0-9]+', ' ');
        s = s.replaceAll('\\s+', ' ').trim();
        return s;
    }

    @TestVisible
    private static Boolean containsNormalizedTerm(String normalizedText, String term) {
        String normalizedTerm = normalize(term);
        if (String.isBlank(normalizedText) || String.isBlank(normalizedTerm)) {
            return false;
        }
        String haystack = ' ' + normalizedText + ' ';
        String needle   = ' ' + normalizedTerm + ' ';
        return haystack.contains(needle);
    }
}