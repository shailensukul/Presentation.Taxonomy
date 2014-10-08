if (SUKUL == undefined) var SUKUL;
if (!SUKUL) SUKUL = {};
if (SUKUL.Reports == undefined) SUKUL.Reports = {};

if (SUKUL.Reports.Staff == undefined) {
    SUKUL.Reports.Staff = function () {
        var self = this;

        self.Execute = function () {
            var clientContext = new SP.ClientContext("/");
            var list = clientContext.get_web().get_lists().getByTitle('Staff');

            var camlQuery = new SP.CamlQuery();
            camlQuery.set_viewXml("<View><Query><Where><Eq><FieldRef Name='IsStaffRoomLeader' /><Value Type='Text'>TRUE</Value></Eq></Where>" +
                "<ViewFields><FieldRef Name='FullName' /><FieldRef Name='EmailAddress' /></ViewFields></Query><RowLimit>100</RowLimit></View>");

            self.listItems = list.getItems(camlQuery);

            clientContext.load(self.listItems);
            clientContext.executeQueryAsync(Function.createDelegate(this, self.dataLoaded),
                Function.createDelegate(this, self.onRequestFailed));
        };

        self.dataLoaded = function () {
            var listItemEnumerator = self.listItems.getEnumerator();
            var ul = $("<ul style='list-style-type: none; padding-left: 0px;' class='cbs-List'>");
            while (listItemEnumerator.moveNext()) {
                var listItem = listItemEnumerator.get_current();

                var htmlStr = "<li style='display: inline;'><div style='width: 320px; display: table; margin-bottom: 10px; margin-top: 5px;'>";
                htmlStr += "<a href='mailto:" + listItem.get_item('EmailAddress') + "'>" + listItem.get_item('FullName1') + "</a>";
                htmlStr += "</li>";
                ul.append($(htmlStr));
            }
            ul.append("</ul>");
            $("#divContentContainer").html(ul);
        };

        self.onRequestFailed = function (sender, args) {
            alert('Error: ' + args.get_message());
        }
    }
}