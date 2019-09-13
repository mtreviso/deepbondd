#!/usr/bin/env bash

python3 -m deepbond train \
                      --seed 42 \
					  --output-dir "runs/test-cinderela-togo/" \
                      --save "saved-models/test-cinderela-togo/" \
                      --tensorboard \
                      --final-report \
                      \
                      --train-path "data/transcriptions/folds/CCL-A/0/train/" \
					  --dev-path "data/transcriptions/folds/CCL-A/0/test/" \
					  --punctuations ".?!" \
					  \
                      --max-length 9999999 \
                      --min-length 0 \
                      \
                      --vocab-size 9999999 \
                      --vocab-min-frequency 1 \
                      --keep-rare-with-vectors \
					  --add-embeddings-vocab \
                      \
                      --model rcnn \
                      \
                      --emb-dropout 0 \
                      --freeze-embeddings \
                      --embeddings-format "word2vec" \
                      --embeddings-path "data/embeddings/word2vec/pt_word2vec_sg_600.kv.emb" \
                      \
                      --use-conv \
                      --conv-size 96 \
                      --kernel-size 7 \
                      --pool-length 3 \
                      \
                      --use-rnn \
                      --rnn-type gru \
                      --hidden-size 100 \
                      --bidirectional \
                      --sum-bidir \
                      --dropout 0.5 \
                      \
                      --use-attention \
                      --use-linear \
                      \
					  --loss-weights "balanced" \
					  --train-batch-size 8 \
					  --dev-batch-size 8 \
					  --epochs 10 \
					  --optimizer "rmsprop" \
					  --save-best-only \
					  --early-stopping-patience 5 \
					  --restore-best-model \

exit;

python3 -m deepbond predict \
                      --load "saved-models/test-cinderela-togo/" \
					  --prediction-type classes \
					  --output-dir "predictions/testing-cinderela/" \
					  --test-path "data/transcriptions/folds/CCL-A/0/test/" \
					  # --text "Há livros escritos para evitar espaços vazios na estante ."

