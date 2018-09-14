# Nescio

This document describes the Nescio privacy Domain Specific Language (DSL).

## Goal

Nescio (latin for: "I do not know") is a DSL that allows declarative anonymization of data. This can be binary data, or textual data. Nescio only requires that there is some kind of structure of the data. The anonymization rules described in relation to this structure. For now, it does not automatically recognize the contents of data.

Nescio is a DSL that tries to help any technically minded person to understand how a certain type of data is anonymized. It contains rules (or patterns) on what should be anonymized and a actionable description of how it should be anonymized. Nescio allows the user to choose between multiple kinds of (pseudo-)anonymizations to apply.

The main goal of Nescio is to avoid the discrepancy between a document that describes the anonymization policy, and the software that implements it. Nescio is a readable description of this policy, a Nescio description can automatically be translated to application that executes this policy.

## Main design philosophy of Nescio

Nescio is data format agnostic. It requires the data format to have graph or tree like structure. Nescio imports the description of a data format from foreign descriptors/plugins. These descriptions are used during type checking and other IDE features. Any new kind of data format has to be