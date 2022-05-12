terraform {
  required_providers {
    namecheap = {
      source  = "namecheap/namecheap"
      version = ">= 2.0.0"
    }
  }
}

# Username, API_user and API_key provided by script
provider "namecheap" {
  use_sandbox = false
}

resource "namecheap_domain_records" "protonmail_records" {
    domain = var.domain_name
    mode = "OVERWRITE"
    email_type = "MX"

    record {
        hostname = "@"
        type = "TXT"
        address = "protonmail-verification=751a1a9a1a94eec588b9ed589c062d3179ba50ea"
    }

    # MX
    record {
        hostname = "@"
        type = "MX"
        address = "mail.protonmail.ch"
        mx_pref = 10
    }

    record {
        hostname = "@"
        type = "MX"
        address = "mailsec.protonmail.ch"
        mx_pref = 20
    }

    # SPF
    record {
        hostname = "@"
        type = "TXT"
        address = "v=spf1 include:_spf.protonmail.ch mx ~all"
    }

    # DKIM
    record {
        hostname = "protonmail._domainkey"
        type = "CNAME"
        address = "protonmail.domainkey.dgwlo6dwz4jiqkk7kyg6eov25eu3ar4kiaxvwoxhcnyryrj62adva.domains.proton.ch."
    }

    record {
        hostname = "protonmail2._domainkey"
        type = "CNAME"
        address = "protonmail2.domainkey.dgwlo6dwz4jiqkk7kyg6eov25eu3ar4kiaxvwoxhcnyryrj62adva.domains.proton.ch."
    }

    record {
        hostname = "protonmail3._domainkey"
        type = "CNAME"
        address = "protonmail3.domainkey.dgwlo6dwz4jiqkk7kyg6eov25eu3ar4kiaxvwoxhcnyryrj62adva.domains.proton.ch."
    }

    # DMARC
    record {
        hostname = "_dmarc"
        type = "TXT"
        address = "v=DMARC1; p=none"
    }
}
