# Nescio: A DSL to describe anonymization rules

Nescio (latin for: "I do not know") is a DSL that allows declarative anonymization of data. This can be binary data, or textual data. Nescio only requires that there is some kind of structure in the data. The anonymization rules are described in relation to this structure.

The goal is to help any technically-minded person to understand how a certain type of data is anonymized. A Nescio specification contains rules (or patterns) on what should be anonymized and an actionable description of how it should be anonymized. 

Nescio allows the user to choose between multiple kinds of (pseudo-)anonymizations to apply. Aiming at more flexibility, the anonymization algorithms are defined using Java.

The main idea behind Nescio is to avoid the discrepancy between a document that describes the anonymization policy, and the software that implements it. Nescio is a readable description of this policy, a Nescio description can automatically be translated to application that executes this policy.
