## classification of intermediate data 1) .qza: analyzed data file obtained from commend, 2) .qzv: visulaization of data in .qza place the .qzv file to https://view.qiime2.org/ to get image data from .qzv file


#import data

qiime tools import --type 'SampleData[PairedEndSequencesWithQuality]' --input-path /data/pbi_sub/analysis/abies_koreana/A_koreana_16s/16smanifest.csv --output-path /data/pbi_sub/analysis/abies_koreana/A_koreana_16s/demux.qza --input-format PairedEndFastqManifestPhred33

#viualize imported data

qiime demux summarize --i-data demux.qza --o-visualization demux.qzv

#trimmed primers

qiime cutadapt trim-paired --i-demultiplexed-sequences demux.qza --p-front-f ACTCCTACGGGAGGCAGCAG --p-front-r GGACTACHVGGGTWTCTAAT --p-no-match-read-wildcards --p-discard-untrimmed --p-match-adapter-wildcards --o-trimmed-sequences primer_trimed.qza --p-cores 32 --verbose

#visualized trimmed data

qiime demux summarize --i-data primer_trimed.qza --o-visualization primer_trimed.qzv


#Denoise with DADA2


qiime dada2 denoise-paired --i-demultiplexed-seqs primer_trimed.qza --p-trunc-len-f 280 --p-trunc-len-r 260 --p-max-ee-f 2 --p-max-ee-r 2 --p-trunc-q 2 --p-chimera-method consensus --o-table table-denoise.qza --o-representative-sequences denoise-rep-seq.qza --o-denoising-stats denoise-stats.qza --p-n-threads 30

## try this if you lose too many reads: qiime dada2 denoise-paired --i-demultiplexed-seqs primer_trimed.qza --p-trunc-len-f 280 --p-trunc-len-r 260 --p-max-ee-f 5 --p-max-ee-r 5 --p-trunc-q 5 --p-chimera-method consensus --o-table table-denoise.qza --o-representative-sequences denoise-rep-seq.qza --o-denoising-stats denoise-stats.qza --p-n-threads

#visualize ouputs from denoise 
qiime feature-table summarize --i-table table-denoise.qza --o-visualization table-denoise.qzv --m-sample-metadata-file metadata.tsv

qiime metadata tabulate --m-input-file denoise-stats.qza --o-visualization denoise-stats.qzv

qiime feature-table tabulate-seqs --i-data denoise-rep-seq.qza --o-visualization denoise-rep-seq.qzv

#Classify the OTU based on classifier.qza
#input;  --i-classifier : trained classifier from machine learning, --i-reads : denoised metadata sequences (ex: rep-seqs.qza from DADA2)
#output: --o-classification

echo "start classification"

qiime feature-classifier classify-sklearn --p-n-jobs 50 --i-classifier silva_16S_classifier.qza --i-reads denoise-rep-seq.qza --o-classification silva_16S_taxonomy.qza

echo "complete classification"

#visualized classified OTU
qiime metadata tabulate --m-input-file silva_16S_taxonomy.qza --o-visualization silva_16S_taxonomy.qzv

#make bar plot from classified OTU
qiime taxa barplot --i-table table-denoise.qza --i-taxonomy silva_16S_taxonomy.qza --m-metadata-file metadata.tsv --o-visualization bar-plot-silva_16S.qzv

###################################################################################################################################################################################

#if your samples include some parts of plant tissues (e.g. endophyte analysis of tree), you have to remove mitochondria and chloroplast OTU information as follows. 

qiime taxa filter-table --i-table table-denoise.qza --i-taxonomy silva_16S_taxonomy.qza --p-include p__ --p-exclude mitochondria,chloroplast --o-filtered-table table_no_mito_chlo.qza

qiime taxa filter-seqs --i-sequences denoise-rep-seq.qza --i-taxonomy silva_16S_taxonomy.qza --p-include p__ --p-exclude mitochondria,chloroplast --o-filtered-sequences rep-seq_no_mito_chlo.qza

###################################################################################################################################################################################


#build a phylogenetic tree using fasttre and mafft alignment
qiime phylogeny align-to-tree-mafft-fasttree --i-sequences denoise-rep-seq.qza --o-alignment aligned-rep-seqs.qza --o-masked-alignment masked-aligned-rep-seqs.qza --o-tree unrooted-tree.qza --o-rooted-tree rooted-tree.qza 

#generate alpha rarefraction curves
#--p-max-depth is recommended to use the median frequency value of “Frequency per sample” information in "FeatureData[Sequence]" obtained from denoise step. 

qiime diversity alpha-rarefaction --i-table table-denoise.qza --i-phylogeny rooted-tree.qza --p-max-depth 82860 --m-metadata-file metadata.tsv --o-visualization alpha_rarefaction82860.qzv


#diversity analysis: compute several alpha and beta diversity metrics => use this output for next step analyses. 

qiime diversity core-metrics-phylogenetic --i-phylogeny rooted-tree.qza --i-table table-denoise.qza --p-sampling-depth 64969 --m-metadata-file metadata.tsv --output-dir core-metrics-results

#beta group significance test 

qiime diversity beta-group-significance --i-distance-matrix core-metrics-results/weighted_unifrac_distance_matrix.qza --m-metadata-file metadata.tsv --m-metadata-column phenotype --o-visualization core-metrics-results/weighted-unifrac-body-site-significance.qzv --p-pairwise


#alpha group significance test
#Faith’s Phylogenetic Diversity (a qualitiative measure of community richness that incorporates phylogenetic relationships between the features)
qiime diversity alpha-group-significance --i-alpha-diversity core-metrics-results/faith_pd_vector.qza --m-metadata-file metadata.tsv --o-visualization core-metrics-results/faith-pd-group-significance.qzv

#Evenness (or Pielou’s Evenness; a measure of community evenness)
qiime diversity alpha-group-significance --i-alpha-diversity core-metrics-results/evenness_vector.qza --m-metadata-file metadata.tsv --o-visualization core-metrics-results/evenness-group-significance.qzv

#Principal Coordinates Analysis (PCoA)
qiime emperor plot --i-pcoa core-metrics-results/unweighted_unifrac_pcoa_results.qza --m-metadata-file metadata.tsv --o-visualization core-metrics-results/unweighted_unifrac_PCoA.qzv
qiime emperor plot --i-pcoa core-metrics-results/bray_curtis_pcoa_results.qza --m-metadata-file metadata.tsv --o-visualization core-metrics-results/bray-curtis_PCoA.qzv



###run picrust2 to estimate biological function of metagenomics data (only useful for 16S data), we have to used qiime2-2021.11 version to use picrust2 plugin

conda activate qiime2-2021.11
qiime picrust2 full-pipeline --i-table table_no_mito_chlo.qza --i-seq rep-seq_no_mito_chlo.qza --output-dir q2-picrust2_output --p-threads 100 --verbose

#export picrust2 data as tsv excel file 

qiime tools export --input-path ko_metagenome.qza --output-path ko_metagenome && biom convert -i ko_metagenome/feature-table.biom -o ko_metagenome/ko_metagenome.tsv --to-tsv



#preparation for qiime2LEfSe
qiime taxa collapse --i-table table_no_mito_chlo.qza --o-collapsed-table collapse.table.qza --p-level 4 --i-taxonomy silva_16S_no_mito_chlo_taxonomy.qza
qiime feature-table relative-frequency --i-table collapse.table.qza --o-relative-frequency-table collapse.frequency.table.qza
qiime tools export --input-path collapse.frequency.table.qza --output-path collapse.frequency
biom convert -i collapse.frequency/feature-table.biom -o collapse.frequency/collapse.frequency.table.txt --to-tsv



















