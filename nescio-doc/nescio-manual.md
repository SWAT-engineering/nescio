# Nescio - A DSL for anonymization of binary data

Nescio (latin for: "I do not know") is a DSL that allows declarative anonymization of data. This can be binary data, or textual data. Nescio only requires that there is some kind of structure in the data. The anonymization rules are described in relation to this structure.

Nescio tries to help any technically-minded person to understand how a certain type of data is anonymized. It contains rules (or patterns) on what should be anonymized and an actionable description of how it should be anonymized. Nescio allows the user to choose between multiple kinds of (pseudo-)anonymizations to apply. Aiming at more flexibility, the anonymization algorithms are defined using Java.

The main goal of Nescio is to avoid the discrepancy between a document that describes the anonymization policy, and the software that implements it. Nescio is a readable description of this policy, a Nescio description can automatically be translated to application that executes this policy.

## Main design philosophy of Nescio

Nescio is data format agnostic. It only requires the data format to have graph- or tree-like structure. Nescio imports the description of a data format using data definition language-specific plugins, e.g. a plugin for XML schema. These plugins allow the Nescio infrastructure to correctly navigate formats described in that specific language during type checking and code generation. For the latter, Nescio requires a specific implementation that interprets path queries and execute Nescio's privacy primitives on the data that is matched.

## Nescio and Bird

For illustrating how Nescio works, we are going to use the Bird data description language throughout this document. Bird is a DSL to describe binary file formats . Such a description of a format is declarative: it describes how the format looks like but does not describe how it can be parsed. The basic metaphor in Bird is that each token definition has its own type. These are excertps of a Bird definition of the PCAP network capture format and the TCP/IP format, with which we want to illustrate the way data tokens are mapped to user-defined structs.

```
module network::PCAP

import network::TCP_IP

struct PCAP {
	GlobalHeader header
	Packet[] packets
	RawProtocolData[] ipPackets = [parse (p.data) with RawProtocolData(p.ipHeader.protocol.as[int]) | p <- packets]
}

struct Packet {
	PacketHeader header
	EthernetHeader ethHeader
	network::TCP_IP::IPv4Header ipHeader 
	byte[] data[ipHeader.dataSize]
}
...
```

```
module network::TCP_IP

struct IPv4Header {
    u8 versionAndLength //?((this & 0b1111_0000) >> 4 == 4B)
    int headerLength = (versionAndLength & 0b1111).as[int] * 4
    u8 _
    u16 totalPacketLength 
    int dataSize = totalPacketLength.as[int] - headerLength
    u16 identification
    u16 fragmentFlagsAndOffset //?(this >> 15 == 0B)
    u8 ttl
    u8 protocol
    u16 checksum
    u32 srcAddress
    u32 dstAddress
    byte[] options [headerLength - (5 * 4)]
}
...
```

## Using Nescio

Consider a very simple anonymization of some network traffic captured in a PCAP file: We want to obfuscate the source and the destination address in the IP header of a network packet. The following Nescio definition does that using two very simple transformations to "hide" the data:


```nescio
module DestinationAddressAnonymization
	forLanguage bird
	rootNode PCAP

import network::TCP_IP
import network::PCAP

str TO_REPLACE_CHARACTER = "X"
str DEFAULT_ENCODING = "UTF-8"

rule anonymizeDestAddress1:
	/**/Packet/ipHeader/destAddress => toZeros

rule anonymizeDestAddress2:
	/**/Packet/ipHeader/destAddress => toChar(TO_REPLACE_CHARACTER, DEFAULT_ENCODING)

@(engineering.swat.nescio.algorithms.ToZeros.apply)
algorithm toZeros()

@(engineering.swat.nescio.algorithms.ToChar.apply)
algorithm toChar(str ch, str encoding)
```

####Dissecting a Nescio specification

*Module declaration*

```nescio
module DestinationAddressAnonymization
	forLanguage bird
	rootNode PCAP
```

The module definition consists of:

- The name of the module.
- The language that will be used when importing data definitions (and for which a Nescio plugin has been developed).
- The root node that will be used as to start the search for the information to anonymize. Notice that in this case this corresponds to the `PCAP` type in the imported files. If there are two types with the same name in two different modules, this name must be fully qualified. In this case, it would be: `network2::PCAP::PCAP`.

*Import directives*

```nescio
import network::TCP_IP
import network::PCAP
```

For importing modules, we need to specify their fully qualified names. The nesting structure is delimited by double colons. The nescio bridge for a particular language will translate this syntax into the custom syntx for name qualification. In this case, we are importing two modules, `TCP_IP` and `PCAP`, both residing in package `network`.

*Constants*

```nescio
str TO_REPLACE_CHARACTER = "X"
str DEFAULT_ENCODING = "UTF-8"
```

For convenience purposes, we can define constants for certain primitive data that we will be using as parameters of tansformation functions. The allowed types are listed in the _Transformation declarations_ section below.

*Rules*

```nescio
rule anonymizeDestAddress1:
	/**/Packet/ipHeader/srcAddress => toZeros

rule anonymizeDestAddress2:
	/**/Packet/ipHeader/dstAddress => toChar(TO_REPLACE_CHARACTER, DEFAULT_ENCODING)
```

Rules consist of three components:

- The unique name of the rule.
- The pattern to match pieces of information in the parsed data (before `=>`).
- The reference to a (possibly parameterized) transformation that defines what to do with the matched data (after `=>`). In our example, we have a parameterless reference to the `toZeros` transformation (which does not accept arguments), and a reference to the `toChar` transformation that expects one string argument (in order to replace each matched byte with the provided one-character string).


Nescio's type checker can estimate if the path patterns are valid by analyzing if the structure of the graph allows for a certain sequence/nesting of fields and types.

Let us have a closer look at the way we specify the patterns. The following table shows the kind of patterns supported by Nescio (in the examples column, `P` is a palceholder for an arbitrary pattern).

| Name| Syntax| Example| 
| ---      |  ------  |----------|   
| Field pattern| _P_ / fieldName | /**/Packet/ipHeader/ |
| Type pattern  | _P_ / [typeName] | /**/Packet/[IPHeader]/ | 
| Deep match  pattern  | _P_ /**/TypeName  | see the beginning of the two examples above| |

- Given data that was matched with pattern _P_, a field pattern gets all the children in such data such that its name is `fieldName`.
- Given data that was matched with pattern _P_, a type pattern gets all the children in such data such that its type has `TypeName` as name.
- Given data that was matched with pattern _P_, a deep match pattern gets all the aribitrarily nested children whose type has `TypeName` as name.

Notice that a `TypeName` can be qualified or unqualified. In the latter case, some implicit name resolution is performed.

Every pattern implicitly starts in the root node defined in the module header.

*Transformation declarations*

```nescio
@(engineering.swat.nescio.algorithms.ToZeros.apply)
algorithm toZeros()

@(engineering.swat.nescio.algorithms.ToChar.apply)
algorithm toChar(str ch, str encoding)
```

Algorithms are programmed in Java and mapped as shown hereover. For illustrative purposes, let us see how the `ToChar` Java class is implemented:

```java
public class ToChar {

	public static byte[] apply(byte[] bytes, String ch, String charset) {
		if (ch == null)
			throw new RuntimeException("Argument to ToChar.apply not provided");
		if (ch.length() != 1)
			throw new RuntimeException("Argument to ToChar.apply must be a string of length 1");
		
		byte[] output = new byte[bytes.length];
		byte replacement;
		try {
			replacement = ch.getBytes(charset)[0];
			for (int i =0; i< bytes.length; i++)
				output[i] = replacement;
			return output;
		} catch (UnsupportedEncodingException e) {
			throw new RuntimeException(e);
		
		}
	}
```

## Bird/Nescio IDE

The Bird/Nescio IDE allows users to develop Bird data descriptions and generate anonymizers based on Nescio specifications.

### Installing the Bird/Nescio IDE

The Bird/Nescio IDE is based on Eclipse and the Rascal Language Workbench (www.rascal-mpl.org/). These are the steps to install it and create a new Bird/Nescio project:

1. Download Eclipse IDE for RCP and RAP Developers, available at www.eclipse.org/downloads/packages/
2. Copy the Bird/Nescio plugin to a local folder (bird-nescio-update-site-1.1.0-SNAPSHOT.zip)
3. Once in the Eclipse IDE, go to the menu Help -> Install New Software...
4. On the "Install" dialog, select "Add..."
5. On the "Add Repository" dialog, select "Archive..." and then select the file downloaded in step 2. The "Location" text box will contain the local address of the file. Click on the button "Add".
6. Back on the "Install" dialog, you can see that there is a new item called "Bird/Nescio DSLs" next to a checkbox. Check it and press "Next>".
7. The Install Details of the selected component are displayed. Press "Next>".
8. The license details for the selected component are displayed. Accept the terms and press "Finish". The plugin will start its installation. At some point, a security warning dialog will be presented. Click on the "Install anyway" button.
9. A dialog soliciting the restart of Eclipse is presented. Click on "Restart Now". After the restart, the Eclipse Bird/Nescio IDE is succesfully installed.

### Creating a blank project on the Bird/Nescio IDE

1. Go to the menu File -> New -> Project...
2. On the "New Project" dialog, select "Bird/Nescio - Bird/Nescio Project" and press "Next>"
3. Name the project and press "Finish"
4. The new project direct structure is ready and displayed on the IDE. Notice there is an "src" folder. Both the Bird descriptions (format .bird) and the Nescio specifications (format .nescio) must be put there, if not physically, via a symlink. there is also a "generated" folder. There inside will be both the Java parsers generated by the Bird descriptions, and the Java anonymizers generated by the Nescio specifications.
5. Configure the details about the docker image on file META-INF/RASCAL.MF, in particular, the base Java package for all the generated code (`BasePackage`).
6. To start the development of an Bird/Nescio module, right click on the project root folder and select the menu New -> Other...
7. (a) To develop a Bird specification: On the "New" dialog, select "Bird/Nescio - Bird Module" and press "Next>".
	(b) To develop a Nescio specification: On the "New" dialog, select "Bird/Nescio - Nescio Module" and press "Next>".
8. Name the module and press "Finish".
9. The new module file (extension .bird or .nescio) is created in folder "generated" and its content is displayed. Notice that it already contains a simple specification as a template.
10. Each time a Bird module is saved, a new Java file containing a parser for such specification is generated on the "generated" folder. 
11. Each time a Nescio module is saved, a new Java file containing the anonymizer based on such specification is generated on the "generated" folder. The parsers for the bird files that this Nescio files import must be generated for this anonymizer to succesfully compile.




