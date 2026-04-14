const { WhatsAble } = require('./dist/nodes/WhatsAble/WhatsAble.node');
const { WhatsAbleTrigger } = require('./dist/nodes/WhatsAble/WhatsAbleTrigger.node');

module.exports = {
  nodes: [
    WhatsAble,
    WhatsAbleTrigger,
  ],
};
