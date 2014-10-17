extend = require('extend')

a = {
  name : {}
  address: {
    country : 'cn'
  }
}
b = {
  name : 'xulei'
  title : 'hr'
  address: {
    city : 'beijing'
  }
}


c = extend(true, b, a)
console.log c
console.log b
console.log a

