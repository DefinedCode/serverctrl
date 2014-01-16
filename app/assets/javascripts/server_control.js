function redirect_to_process(e) {
  if (e.preventDefault) e.preventDefault();
  var domain = location.protocol + '//' + location.host + '/processes/'
  var process_id = document.getElementById("processid").value;
  console.log(process_id);
  window.location = domain + process_id;
  return false;
}

var form = document.getElementById('check_process_form');
if (!(form == null)) {
  if (form.attachEvent) {
    form.attachEvent("submit", redirect_to_process);
  } else {
    form.addEventListener("submit", redirect_to_process);
  }
}