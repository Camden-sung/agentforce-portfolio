# Knowledge Search Index & Retriever

Scaffolded from `docs/meridian_schema_reference_v3.md`. Data Cloud Search
Index / Retriever configuration has poor Metadata API coverage and can't be
read from the org via retrieve, so this is a hand-maintained summary, not a
retrieved/generated artifact.

This is Project 1's Knowledge grounding mechanism — built manually via
**Data 360 > Search Index > Advanced Setup**, not the Agentforce Data
Library (ADL) low-code path.

## As-built (per schema reference v3)

| Component             | Detail                                                                                                                                                                                          |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Search Index          | `Meridian_KB_Body_Index`                                                                                                                                                                        |
| Source DMO            | `ssot__KnowledgeArticleVersion__dlm`                                                                                                                                                            |
| Chunked field         | `Article_Body__c` **only**                                                                                                                                                                      |
| Chunking / embeddings | Passage Extraction / E5 Large V2 (default)                                                                                                                                                      |
| Filter field          | `Category__c`                                                                                                                                                                                   |
| Chunk DMO             | `Meridian_KB_Body_Index_chunk__dlm`                                                                                                                                                             |
| Retriever             | `Meridian_KB_Body_Index Retriever` — returns Chunk + Name + URL; chunks come from the chunk DMO, Name/URL are hydrated from `ssot__KnowledgeArticleVersion__dlm` (Title → Name, URL Name → URL) |
| Result                | 10 clean chunks, one per article. The correct article ranks #1 on all probe questions.                                                                                                          |

## Why not the Agentforce Data Library (ADL)

The ADL path was built, tested, and abandoned. It auto-chunks multiple
Knowledge fields (title, URL name, summary, article number, body), producing
thin title-only and metadata-only chunks. A bare title chunk is a
near-perfect embedding match for a title-like query (e.g. "how do I submit a
service request"), so content-free chunks outranked the real body chunk. The
ADL gives no field-level control — setting "content fields = body only" does
nothing. The manual Advanced Setup index has an explicit **Select Fields to
Chunk** step, which eliminates the problem.

Also: the ADL reuses an existing search index when a new library has the
same identifying fields, so rebuilding via ADL kept returning the same
broken chunks. The old ADL and its retriever/index/chunk DMOs were deleted;
the Knowledge data stream and `ssot__KnowledgeArticleVersion__dlm` survive
independently and feed the manual index instead.

## Consumption

The retriever grounds the `Meridian_Answer_From_Knowledge` prompt template
(Flex template, search query bound to the `Question` input, max results 3).
See `force-app/main/default/genAiPromptTemplates/Meridian_Answer_From_Knowledge.genAiPromptTemplate-meta.xml`.

## TODO — not stated in the reference doc

- Exact Advanced Setup configuration steps/screens (this doc states the
  resulting configuration, not the click-path)
- Index refresh/sync schedule or trigger
- Any additional filter fields beyond `Category__c`
- Embedding model version pinning behavior (doc states "E5 Large V2
  (default)" — unclear if this was an explicit choice or the platform default)

These should be confirmed by opening the index in Data Cloud > Search Index
before Project 2/3 builds anything that depends on this retriever's exact
behavior.
