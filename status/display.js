'use strict'

const data = require(`./${process.argv[2]}`)
const item = data.doingArray[0]
console.log(`${item.dtime}\n\t${item.rootContent}`)
