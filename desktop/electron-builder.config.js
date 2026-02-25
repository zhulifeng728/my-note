module.exports = {
  appId: 'com.notes.desktop',
  productName: '笔记应用',
  directories: {
    output: 'release',
  },
  files: [
    'dist/**/*',
    'dist-electron/**/*',
  ],
  mac: {
    target: ['dmg', 'zip'],
    category: 'public.app-category.productivity',
  },
  win: {
    target: ['nsis', 'zip'],
  },
}
