# Nescio

This document describes the Nescio privacy Domain Specific Language (DSL).

## Goal

Nescio (latin for: "I do not know") is a DSL that allows declarative anonymization of data. This can be binary data, or textual data. Nescio only requires that there is some kind of structure of the data. The anonymization rules described in relation to this structure. For now, it does not automatically recognize the contents of data.

Nescio is a DSL that tries to help any technically minded person to understand how a certain type of data is anonymized. It contains rules (or patterns) on what should be anonymized and a actionable description of how it should be anonymized. Nescio allows the user to choose between multiple kinds of (pseudo-)anonymizations to apply.

The main goal of Nescio is to avoid the discrepancy between a document that describes the anonymization policy, and the software that implements it. Nescio is a readable description of this policy, a Nescio description can automatically be translated to application that executes this policy.

## Main design philosophy of Nescio

Nescio is data format agnostic. It requires the data format to have graph or tree like structure. Nescio imports the description of a data format from foreign descriptors/plugins. These descriptions are used during type checking and other IDE features. Secondly, Nescio requires a per data format specific implementation that interprets path queries and execute Nescio's privacy primitives on the data that is matched.

## Architecture

1. `nescio-core`: basis nescio syntax, type checker, and code generator
2. `nescio-engine`: basic infrastructure that any data format that nescio connects too should support. Implementors can choose between Rascal and Java.
3. `nescio-trans`: data transformation library that is used by `nescio-core`

### Nescio core

#### Syntax

```nescio
module AnonymizeIPs

import TCP_IP from bird

str KEY = "30313233343536373839414243444546"

rule HideSrcIP:
    IPPacket/head/srcAddress => encryptFFX(KEY)

rule HideDestIP:
    IPPacket/head/dstAddress => replaceZeros()

// The same two rules above can be replaced by a deep matching policy
rule HideAllIPs:
    // Match all nodes whose type is IPAddress
    **/[IPAddress] => encryptFFX(KEY)

@(nl.cwi.anon.EncryptFormatPreserving)
algorithm encryptFFX(str key)
```

In this example we see how Nescio defines an import of a data structure out of the bird language. Then it defines two rules to match a specific field in the `IPPacket` token defined in BIRD and describes that these two addresses found should be encrypted with the `encryptFFX` function. The last rule (`HideAllIPs`) shows an alternative tree pattern that does a deep match on the graph, and matches anything that is of the _Type_ `IPAddress`, not that Nescio does not allow for generic format recognition (as an IP address is just encoded as 4 bytes, it wouldn't make sense to match all 4 bytes that look like an IP address).

#### Type checker

Nescio's type checker can estimate if the path patterns are valid by analyzing if the structure of the graph allows for a certain sequence/nesting of fields and types.

### Nescio engine

Nescio's engines are the format specific implementations. Nescio engine defines an API that the format implementation must adhere too. The base API is defined in Rascal, but the mapping to Java is also provided.

#### API

```rascal
module nescio::engine::API

import util::Reflective;

data Engine = format(
    str formatIdentifier,
    str formatName,
    StructuredGraph (str module, PathConfig cfg) calculateGraph,
    void(str name, StructuredGraph graph, Transformations transformations, PathConfig cfg) generateApplication)
);

alias Transformations = rel[str ruleName, Path, Action];

data StructuredGraph
    = module(str name, rel[str typeName, str field, str fieldType] definedFields);

data Path
    = field(str fieldName)
    | derefField(str fieldName, Path child)
    | rootType(str typeName, Path child)
    | deepMatchType(str typeName)
    | deepMatchType(str typeName, Path child)
    ;

data Action
    = remove()
    | replaceZeros()
    | javaFunction(str className, str functionName)
    ;
```

```java
package engineering.swat.nescio.action;

/**
 * Interface that all actions should implement (the `javaFunction` reference in the Rascal Action ADT)
 */
public interface TransformAction {
    /**
     * Does the transformation produce the same amount of bytes as the input
     */
    default boolean isInPlace() {
        return false;
    }

    /**
    * Given an inputSize, make a reasonable estimate for the output size, to help allocate buffers
    */
    int estimateOutputSize(int inputSize);

    /**
     * Perform an in-place transform of a ByteBuffer
     * (should only be called if {@link #isInPlace()} returns true)
     */
    default void transform(ByteBuffer data) {
        throw new IllegalArgumentException("This transformer does not support inplace transformations");
    }

    /**
     * Transform all the data from the source stream and write the output to the target stream
     *
     * @returns the amount of bytes written to the target stream
     */
    int transform(InputStream source, OutputStream target);
}
```

#### API Explained

A nescio engine (for a certain data format) that is responsible for three parts:

1. Provide a static structure of the data format (which fields under which nested name)
2. Provide a code generator that translate the Path AST to a format specific search implementation, and correctly implements the `Action` ADT.
3. 





# TODO

- sometimes, like for example for JSON, the intermediate nodes do not have a type name, there is only a structure on what is nested inside what. maybe the `StructuredGraph` data type should be more generic to also handle this.
- how to encode arity of the structures in the graph