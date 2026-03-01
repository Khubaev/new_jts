module.exports = {
  JWT_SECRET: process.env.JWT_SECRET || 'change-me-in-production',
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '24h',
  BODY_LIMIT: process.env.BODY_LIMIT || '12mb',
  MAX_PHOTO_SIZE: 5 * 1024 * 1024, // 5 MB
  MAX_PHOTOS_PER_REQUEST: 10,
  TITLE_MAX_LENGTH: 200,
  DESCRIPTION_MAX_LENGTH: 5000,
  PRIORITY_VALUES: ['Низкий', 'Средний', 'Высокий', 'Критический'],
};
