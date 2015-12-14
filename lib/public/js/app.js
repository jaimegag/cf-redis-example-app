function killApp() {
    console.log("killing application");
    $.ajax({
    	url: "/killSwitch",
    	type: "GET",
    	success: function(data) {
    	   console.log("killApp call ok");
    	},
    	error: function() {
    	   console.log("killApp call failure");
    	}
    });
}

function goRedisUI() {
    window.location = "/redisUI";
}

function goHome() {
    window.location = "/";
}

function saveData() {
    var key = $('#store_key').val();
    var value = $('#store_value').val();
    console.log("Saving data: key={" + key + "} value={" + value + "}");
    var putdata = {data: value};
    $.ajax({
        url: "/store/" + key,
        type: "PUT",
        data: putdata,
        success: function(data) {
            console.log("saveData call ok");
            $('#saveresult').html("Data saved successfully");
            $('#saveresult').removeClass("hiddenelement");
            $('#redisdata > tbody:last-child').append('<tr class="backblue"><td>' + key + '</td><td>' + value + '</td></tr>');
            var delay = 3000;
            setTimeout(function() {
                $('#saveresult').addClass("hiddenelement");
                $('#store_key').val('');
                $('#store_value').val('');
            }, delay);
        },
        error: function() {
            console.log("saveData call failure");
            $('#saveresult').html("Data saving failed");
            $('#saveresult').removeClass("hiddenelement");
        }
    });
}