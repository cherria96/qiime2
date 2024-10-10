#plugin q2-vsearch (https://github.com/qiime2/q2-vsearch.git)
#plugin q2-quality-filter (https://github.com/qiime2/q2-quality-filter)

$INPUT=demux-paired-end.qza

#joining reads
qiime vsearch join-pairs \
  --i-demultiplexed-seqs $INPUT \
  --o-joined-sequences demux-joined.qza

#view summary
qiime demux summarize \
  --i-data demux-joined.qza \
  --o-visualization demux-joined.qzv

#quality control
qiime quality-filter q-score-joined \
  --i-demux demux-joined.qza \
  --o-filtered-sequences demux-joined-filtered.qza \
  --o-filter-stats demux-joined-filter-stats.qza

#denoising with deblur
qiime deblur denoise-16S \
  --i-demultiplexed-seqs demux-joined-filtered.qza \
  --p-trim-length 270 \
  --o-representative-sequences rep-seqs.qza \
  --o-table table.qza \
  --p-sample-stats \
  --o-stats deblur-stats.qza

#view summary
qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv

qiime deblur visualize-stats \
  --i-deblur-stats deblur-stats.qza \
  --o-visualization deblur-stats.qzv
