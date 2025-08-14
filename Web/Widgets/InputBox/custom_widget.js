// Subscribes to receive property changes
cwidget.on("PropertyName", function() {

   // Gets property value
   console.log(cwidget.PropertyName);

   // Sets property value
   cwidget.PropertyName = "value"

   // Triggers an event
   cwidget.dispatchEvent("EventName");

});