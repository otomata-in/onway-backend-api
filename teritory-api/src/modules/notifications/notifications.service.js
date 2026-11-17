const prisma = require('../../config/prisma');

/**
 * Notifications are side effects of a mutation: a failure here is logged and
 * swallowed so it can never turn a successful join/start into a 500.
 */
const notify = async ({
  userId,
  type = 'SYSTEM',
  title,
  body,
  icon = null,
  actionUrl = null,
}) => {
  if (!userId || !title || !body) return null;
  try {
    return await prisma.notification.create({
      data: { userId, type, title, body, icon, actionUrl },
    });
  } catch (err) {
    console.error('⚠️  [notify] could not persist notification:', err.message);
    return null;
  }
};

const notifyMany = (items = []) => Promise.all(items.map((item) => notify(item)));

module.exports = { notify, notifyMany };
