#!/usr/bin/env bash

traindb(){
  local fold=$1
  python3 -m deepbond train \
                            --seed 42 \
                            --gpu-id 0  \
                            --output-dir "runs/test-cinderela-togo/" \
                            --save "saved-models/test-cinderela-togo/" \
                            --print-parameters-per-layer \
                            --final-report \
                            \
                            --train-path "data/folds/CCL-A/${fold}/train/" \
                            --dev-path "data/folds/CCL-A/${fold}/test/" \
                            --punctuations ".?!"\
                            --max-length 9999999 \
                            --min-length 0 \
                            \
                            --vocab-size 9999999 \
                            --vocab-min-frequency 1 \
                            --keep-rare-with-vectors \
                            --add-embeddings-vocab \
                            \
                            --embeddings-format "text" \
                            --embeddings-path "data/embs/word2vec/pt_word2vec_sg_600.small.pickle.emb" \
                            --emb-dropout 0.0 \
                            --embeddings-binary \
                            --freeze-embeddings \
                            \
                            --model crf \
                            --hidden-size 100 \
                            \
                            --conv-size 100 \
                            --kernel-size 7 \
                            --pool-length 3 \
                            --cnn-dropout 0.0 \
                            \
                            --rnn-type rnn \
                            --bidirectional \
                            --sum-bidir \
                            --rnn-dropout 0.0 \
                            \
                            --attn-type "multihead" \
                            --attn-scorer "dot_product" \
                            --attn-hidden-size 200 \
                            --attn-dropout 0.5 \
                            --attn-nb-heads 2 \
                            --attn-multihead-hidden-size 34 \
                            \
                            --loss-weights "balanced" \
                            --train-batch-size 1 \
                            --dev-batch-size 1 \
                            --epochs 40 \
                            --optimizer "adamw" \
                            --learning-rate 0.001 \
                            --weight-decay 0.01 \
                            --save-best-only \
                            --early-stopping-patience 10 \
                            --restore-best-model
}


predictdb(){
  local fold=$1
  python3 -m deepbond predict \
                        --gpu-id 0  \
                        --prediction-type classes \
                        --load "saved-models/test-cinderela-togo/" \
                        --test-path "data/folds/CCL-A/${fold}/test/" \
                        --output-dir "data/folds/CCL-A/${fold}/pred/" \
                        --train-batch-size 1 \
                        --dev-batch-size 1
}


###################################
# Train and predict for each fold #
###################################

traindb 0
predictdb 0
python3 scripts/join_original_text_with_predicted_labels.py data/folds/CCL-A/0/test/ data/folds/CCL-A/0/pred/predictions

traindb 1
predictdb 1
python3 scripts/join_original_text_with_predicted_labels.py data/folds/CCL-A/1/test/ data/folds/CCL-A/1/pred/predictions

traindb 2
predictdb 2
python3 scripts/join_original_text_with_predicted_labels.py data/folds/CCL-A/2/test/ data/folds/CCL-A/2/pred/predictions

traindb 3
predictdb 3
python3 scripts/join_original_text_with_predicted_labels.py data/folds/CCL-A/3/test/ data/folds/CCL-A/3/pred/predictions

traindb 4
predictdb 4
python3 scripts/join_original_text_with_predicted_labels.py data/folds/CCL-A/4/test/ data/folds/CCL-A/4/pred/predictions


# Error analysis

python3 scripts/error_analysis.py "data/folds/CCL-A/*/test/*" "data/folds/CCL-A/*/pred/predictions/*"
