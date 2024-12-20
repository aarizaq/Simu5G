//
//                  Simu5G
//
// Authors: Giovanni Nardini, Giovanni Stea, Antonio Virdis (University of Pisa)
//
// This file is part of a software released under the license included in file
// "license.pdf". Please read LICENSE and README files before using it.
// The above files and the present reference are part of the software itself,
// and cannot be removed from it.
//

package simu5g.nodes.mec.VirtualisationInfrastructure;

import inet.common.MessageDispatcher;
import inet.linklayer.ppp.PppInterface;
import inet.networklayer.common.InterfaceTable;
import inet.networklayer.contract.INetworkLayer;
import inet.transportlayer.tcp.Tcp;
import inet.transportlayer.udp.Udp;

import inet.linklayer.contract.IEthernetInterface;
import inet.linklayer.contract.IEthernetLayer;
import inet.linklayer.contract.IIeee8021qLayer;
import inet.linklayer.contract.IIeee8021rLayer;
import inet.linklayer.contract.IIeee8022Llc;
import inet.linklayer.contract.ILoopbackInterface;
import inet.linklayer.contract.IPppInterface;
import inet.linklayer.contract.ITunnelInterface;
import inet.linklayer.contract.IVirtualInterface;
import inet.linklayer.contract.IWirelessInterface;
import inet.networklayer.common.InterfaceTable;
import inet.node.contract.IEthernetNetworkNode;
import inet.protocolelement.contract.IProtocolLayer;


//#
//# VirtualisationInfrastructure
//#
module VirtualisationInfrastructure
{
    parameters:
        @networkNode();
        @display("bgb=1349,1320;i=block/dispatch");
        @figure[applicationLayer](type=rectangle; pos=250,6; size=600,130; lineColor=#808080; cornerRadius=5; fillColor=#ffff00; fillOpacity=0.1);
        @figure[applicationLayer.title](type=text; pos=845,11; anchor=ne; text="application layer");
        @figure[transportLayer](type=rectangle; pos=250,156; size=600,130; fillColor=#ff0000; lineColor=#808080; cornerRadius=5; fillOpacity=0.1);
        @figure[transportLayer.title](type=text; pos=845,161; anchor=ne; text="transport layer");
        @figure[networkLayer](type=rectangle; pos=250,306; size=600,130; fillColor=#00ff00; lineColor=#808080; cornerRadius=5; fillOpacity=0.1);
        @figure[networkLayer.title](type=text; pos=845,311; anchor=ne; text="network layer");
        @figure[linkLayer](type=rectangle; pos=250,456; size=600,130; fillColor=#0000ff; lineColor=#808080; cornerRadius=5; fillOpacity=0.1);
        @figure[linkLayer.title](type=text; pos=845,461; anchor=ne; text="link layer");
        @figure[submodules];

        //# Network Layer specs
        bool hasIpv4 = default(true);
        bool hasIpv6 = default(false);
        *.interfaceTableModule = default(absPath(".interfaceTable"));
        *.routingTableModule = default("^.ipv4.routingTable");

        int numIndependentMecApp = default(0);
        int numExtEthInterfaces = default(0);

    gates:

        inout ppp[];				// connection with GtpEndpoint and local/external networks

        output independentMecAppOut[numIndependentMecApp];			// connection to the ME App input gate
        input independentMecAppIn[numIndependentMecApp];			// connection to the ME App output gate

        output meAppOut[];			// connection to the ME App input gate
        input meAppIn[];			// connection to the ME App output gate

        inout mecPlatform[];			// connection to the MEC Platform

    submodules:

        interfaceTable: InterfaceTable {
            @display("p=61.344,74.976;is=s");
        }

        //#
        //# link-layer modules
        //#
        pppIf[sizeof(ppp)]: PppInterface {
            @display("p=911,1065");
        }

        // ethernet interface used for communicating with external applications in emulation mode
        extEth[numExtEthInterfaces]: <default("ExtLowerEthernetInterface")> like IEthernetInterface {
            parameters:
                @display("p=374,1043,row,150;q=txQueue");
        }
        lo: <default("LoopbackInterface")> like ILoopbackInterface {
            parameters:
                @display("p=657,1083,row,150");
        }

        //#
        //# Network layer module
        //#
        ipv4: <default("Ipv4NetworkLayer")> like INetworkLayer if hasIpv4 {
            parameters:
                @display("p=420.28,372.88;q=queue");
        }
        ipv6: <default("Ipv6NetworkLayer")> like INetworkLayer if hasIpv6 {
            parameters:
                @display("p=657.28,374.46;q=queue");
        }

        //#
        //# Transport layer modules and corresponding application modules
        //#
        udp: Udp {
            @display("p=459,217");
        }

        tcp: Tcp {
            @display("p=627,217");
        }

        // message dispatcher for SAP between application and transport layer
        at: MessageDispatcher {
            parameters:
                @display("p=550,146;b=600,5,,,,1");
        }
        // message dispatcher for SAP between transport and network layer
        tn: MessageDispatcher {
            parameters:
                @display("p=550,296;b=600,5,,,,1");
        }
        // message dispatcher for SAP to link layer
        nl: MessageDispatcher {
            parameters:
                @display("p=550,446;b=600,5,,,,1");
        }

        cb: MessageDispatcher {
            @display("p=750,600;b=1000,5");
        }
        bridging: <default("")> like IProtocolLayer if typename != "" {
            @display("p=548,672");
        }
        bl: MessageDispatcher {
            @display("p=750,750;b=1000,5");
        }
        ethernet: <default(sizeof(extEth) > 0 ? "EthernetEncapsulation" : "")> like IEthernetLayer if typename != "" {
            @display("p=525,816");
        }

        li: MessageDispatcher {
            @display("p=750,900;b=1000,5,,,,1");
        }


    connections allowunconnected:

        for i=0..numIndependentMecApp -1 {
            at.out++ --> independentMecAppOut++;
            at.in++ <-- independentMecAppIn++;
        }

        for i=0..sizeof(mecPlatform)-1 {
            at.out++ --> mecPlatform$o[i];
            at.in++ <-- mecPlatform$i[i];
        }

        //#
        //# App layer to transport layer connections
        //#
        at.out++ --> udp.appIn;
        at.in++ <-- udp.appOut;

        at.out++ --> tcp.appIn;
        at.in++ <-- tcp.appOut;

        bl.out++ --> li.in++;
        li.out++ --> bl.in++;

        nl.out++ --> cb.in++;
        cb.out++ --> nl.in++;

        cb.out++ --> bridging.upperLayerIn if exists(bridging);
        bridging.upperLayerOut --> cb.in++ if exists(bridging);

        bridging.lowerLayerOut --> bl.in++ if exists(bridging);
        bl.out++ --> bridging.lowerLayerIn if exists(bridging);

        cb.out++ --> bl.in++ if !exists(bridging);
        bl.out++ --> cb.in++ if !exists(bridging);

        //#
        //# Transport layer to network layer connections
        //#
        udp.ipOut --> tn.in++;
        udp.ipIn <-- tn.out++;

        tcp.ipOut --> tn.in++;
        tcp.ipIn <-- tn.out++;


        ipv4.ifIn <-- nl.out++ if hasIpv4;
        ipv4.ifOut --> nl.in++ if hasIpv4;

        ipv4.transportIn <-- tn.out++ if hasIpv4;
        ipv4.transportOut --> tn.in++ if hasIpv4;

        //#
        //# Network layer to link layer connections
        //#
        ipv6.ifIn <-- nl.out++ if hasIpv6;
        ipv6.ifOut --> nl.in++ if hasIpv6;

        ipv6.transportIn <-- tn.out++ if hasIpv6;
        ipv6.transportOut --> tn.in++ if hasIpv6;

        for i=0..sizeof(ppp)-1 {
            pppIf[i].upperLayerOut --> li.in++;
            pppIf[i].upperLayerIn <-- li.out++;
            pppIf[i].phys <--> ppp++;
        }


        bl.out++ --> ethernet.upperLayerIn if exists(ethernet);
        ethernet.upperLayerOut --> bl.in++ if exists(ethernet);


        ethernet.lowerLayerOut --> li.in++ if exists(ethernet);
        li.out++ --> ethernet.lowerLayerIn if exists(ethernet);

        for i=0..numExtEthInterfaces-1 {
            li.out++ --> extEth[i].upperLayerIn;
            li.in++ <-- extEth[i].upperLayerOut;
        }

        li.out++ --> lo.upperLayerIn;
        lo.upperLayerOut --> li.in++;
}
