let Uploaders = {}

Uploaders.Tigris = function(entries, onViewError){
  entries.forEach(entry => {
    let formData = new FormData()
    let {url, fields} = entry.meta
    Object.entries(fields).forEach(([key, val]) => formData.append(key, val))
    formData.append("file", entry.file)
    let xhr = new XMLHttpRequest()
    onViewError(() => xhr.abort())
    xhr.onload = () => {
      console.log("Uploaders.Tigris onload.status", xhr.status)
      console.log(entry)
      xhr.status === 200 ? entry.progress(100) : entry.error()
    }

    xhr.onerror = () => {
      console.log("Uploaders.Tigris XHR Error")
      entry.error()
    }
    xhr.upload.addEventListener("progress", (event) => {
      if(event.lengthComputable){
        let percent = Math.round((event.loaded / event.total) * 100)
        if(percent < 100){ 
            entry.progress(percent) 
        }
      }
    })

    xhr.open("POST", url, true)
    xhr.send(formData)
  })
}

export default Uploaders;