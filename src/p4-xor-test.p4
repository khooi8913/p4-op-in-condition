/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

struct metadata {
    /* empty */
    bit<32>     xor_before1;
    bit<32>     xor_before2;
    bit<32>     xor_after1;
    bit<32>     xor_after2;
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4 : parse_ipv4;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  
        /* TODO: checksum function here, if applicable */
    }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }

    action xor_srcAddr () {
        meta.xor_before1 = hdr.ipv4.srcAddr;
        hdr.ipv4.srcAddr = hdr.ipv4.srcAddr ^ 32w0x12345678;
        meta.xor_after1 = hdr.ipv4.srcAddr;
    }

    action xor_dstAddr(){
        meta.xor_before2 = hdr.ipv4.dstAddr;
        hdr.ipv4.dstAddr = hdr.ipv4.dstAddr ^ 32w0x12345678;
        meta.xor_after2 = hdr.ipv4.dstAddr;
    }
    
    action ip_forward(egressSpec_t port) {
        standard_metadata.egress_spec = port;

        if(hdr.ipv4.isValid()) {
            xor_srcAddr();
        }
        if(hdr.ethernet.isValid()) {
            xor_dstAddr();
        }
        
    }
    
    table ipv4_lpm {
        key = {
            standard_metadata.ingress_port : exact;
        }
        actions = {
            ip_forward;
            NoAction;
        }
        const entries = {
            1 : ip_forward(2);
            2 : ip_forward(1);
        }
        default_action = NoAction();
    }

    table debug {
        key = {
            meta.xor_before1 : exact;
            meta.xor_after1 : exact;
            meta.xor_before2 : exact;
            meta.xor_after2 : exact;
        }
        actions = {
            NoAction;
        }
        default_action = NoAction();
    }
    
    apply {
        if(hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
            debug.apply();
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
        update_checksum(
            hdr.ipv4.isValid(),
            { 
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr 
            },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16
            );
    }
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        /* TODO: add deparser logic */
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;