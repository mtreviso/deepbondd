import logging
from pathlib import Path

from deepbond import iterator
from deepbond import models
from deepbond import optimizer
from deepbond import opts
from deepbond import scheduler
from deepbond.dataset import dataset, fields
from deepbond.trainer import Trainer


def run(options):
    logging.info('Running with options: {}'.format(options))

    words_field = fields.WordsField()
    tags_field = fields.TagsField()
    fields_tuples = [('words', words_field), ('tags', tags_field)]

    logging.info('Building train corpus: {}'.format(options.train_path))
    train_dataset = dataset.build(options.train_path, fields_tuples, options)

    logging.info('Building train iterator...')
    train_iter = iterator.build(train_dataset,
                                options.gpu_id,
                                options.train_batch_size,
                                is_train=True)

    dev_dataset = None
    dev_iter = None
    if options.dev_path is not None:
        logging.info('Building dev dataset: {}'.format(options.dev_path))
        dev_dataset = dataset.build(options.dev_path, fields_tuples, options)
        logging.info('Building dev iterator...')
        dev_iter = iterator.build(dev_dataset,
                                  options.gpu_id,
                                  options.dev_batch_size,
                                  is_train=False)

    test_dataset = None
    test_iter = None
    if options.test_path is not None:
        logging.info('Building test dataset: {}'.format(options.test_path))
        test_dataset = dataset.build(options.test_path, fields_tuples, options)
        logging.info('Building test iterator...')
        test_iter = iterator.build(test_dataset,
                                   options.gpu_id,
                                   options.dev_batch_size,
                                   is_train=False)

    datasets = [train_dataset, dev_dataset, test_dataset]
    datasets = list(filter(lambda x: x is not None, datasets))

    # BUILD
    if not options.load:
        logging.info('Building vocabulary...')
        fields.build_vocabs(fields_tuples, train_dataset, datasets, options)
        loss_weights = None
        if options.loss_weights == 'balanced':
            loss_weights = train_dataset.get_loss_weights()
        logging.info('Building model...')
        model = models.build(options, fields_tuples, loss_weights)
        logging.info('Building optimizer...')
        optim = optimizer.build(options, model.parameters())
        logging.info('Building scheduler...')
        sched = scheduler.build(options, optim)

    # OR LOAD
    else:
        logging.info('Loading vocabularies...')
        fields.load_vocabs(options.load, fields_tuples)
        # set dummy loss_weights (the correct values are going to be loaded)
        loss_weights = None
        if options.loss_weights == 'balanced':
            loss_weights = [0] * (len(tags_field.vocab) - 1)
        logging.info('Loading model...')
        model = models.load(options.load, fields_tuples, loss_weights)
        logging.info('Loading optimizer...')
        optim = optimizer.load(options.load, model.parameters())
        logging.info('Loading scheduler...')
        sched = scheduler.load(options.load, optim)

    # STATS
    logging.info('Word vocab size: {}'.format(len(words_field.vocab)))
    logging.info('Tag vocab size: {}'.format(len(tags_field.vocab) - 1))
    logging.info('Number of training examples: {}'.format(len(train_dataset)))
    if dev_dataset:
        logging.info('Number of dev examples: {}'.format(len(dev_dataset)))
    if test_dataset:
        logging.info('Number of test examples: {}'.format(len(test_dataset)))

    # TRAIN
    logging.info('Building trainer...')
    trainer = Trainer(train_iter, model, optim, sched, options,
                      dev_iter=dev_iter, test_iter=test_iter)

    if options.resume_epoch and options.load is None:
        logging.info('Resuming training...')
        trainer.resume(options.resume_epoch)

    trainer.train()

    # SAVE
    if options.save:
        logging.info('Saving path: {}'.format(options.save))
        config_path = Path(options.save)
        config_path.mkdir(parents=True, exist_ok=True)
        logging.info('Saving config options...')
        opts.save(config_path, options)
        logging.info('Saving vocabularies...')
        fields.save_vocabs(config_path, fields_tuples)
        logging.info('Saving model...')
        models.save(config_path, model)
        logging.info('Saving optimizer...')
        optimizer.save(config_path, optim)
        logging.info('Saving scheduler...')
        scheduler.save(config_path, sched)

    return fields_tuples, model, optim, sched