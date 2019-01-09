import ballerina/io;
import celleryio/cellery;

cellery:Component helloWorldComp = {
    name: "HelloWorld",
    source: {
        image: "sumedhassk/hello-world:1.0.0"
    },
    ingresses: [
        {
            name: "hello",
            port: "9090:80",
            context: "hello",
            definitions: [
                {
                    path: "/",
                    method: "GET"
                }
            ]
        }
    ]
};

cellery:CellImage helloCell = new("Hello-World");

public function celleryBuild() {
    helloCell.addComponent(helloWorldComp);

    helloCell.apis = [
        {
            targetComponent:helloWorldComp.name,
            context: helloWorldComp.ingresses[0],
            global: true
        }
    ];

    var out = cellery:createImage(helloCell);
    if(out is boolean) {
        io:println("Hello Cell Built successfully.");
    }
}

