#!/bin/bash

#conda activate qiime2
#conda install -c conda-forge -c bioconda -c qiime2 -c defaults xmltodict
#pip install git+https://github.com/bokulich-lab/RESCRIPt.git
#pip list | grep joblib
#if joblib == 1.2.0 ==> downgrade to 1.1.0
#pip install joblib==1.1.0

mkdir SILVA_DB_138_99
cd SILVA_DB_138_99

SILVA_RNASEQ=silva-rna-seqs.qza
SILVA_TAX=silva-tax.qza
SILVA_DNA=silva-seqs.qza
SILVA_CLEAN=silva-clean-seqs.qza
SILVA_FILT=silva-filt-seqs.qza
SILVA_DISC=silva-disc-seqs.qza
SILVA_UNIQ=silva-uniq-seqs.qza
SILVA_UNIQ_TAX=silva-uniq-tax.qza

qiime rescript get-silva-data \
    --p-version '138.1' \
    --p-target 'SSURef_NR99' \
    --p-include-species-labels \
    --o-silva-sequences $SILVA_RNASEQ \
    --o-silva-taxonomy $SILVA_TAX

qiime rescript reverse-transcribe \
    --i-rna-sequences $SILVA_RNASEQ \
    --o-dna-sequences $SILVA_DNA

qiime rescript cull-seqs \
    --i-sequences $SILVA_DNA \
    --o-clean-sequences $SILVA_CLEAN

qiime rescript filter-seqs-length-by-taxon \
    --i-sequences $SILVA_CLEAN \
    --i-taxonomy $SILVA_TAX \
    --p-labels Archaea Bacteria Eukaryota \
    --p-min-lens 900 1200 1400 \
    --o-filtered-seqs $SILVA_FILT \
    --o-discarded-seqs $SILVA_DISC

qiime rescript dereplicate \
    --i-sequences $SILVA_FILT  \
    --i-taxa $SILVA_TAX \
    --p-rank-handles 'silva' \
    --p-mode 'uniq' \
    --o-dereplicated-sequences $SILVA_UNIQ \
    --o-dereplicated-taxa $SILVA_UNIQ_TAX


