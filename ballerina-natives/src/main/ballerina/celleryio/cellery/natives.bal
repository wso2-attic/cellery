// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
import ballerina/log;


public const string TEAM = "TEAM";
public const string OWNER = "OWNER";
public const string MAINTAINER = "MAINTAINER";

# Pre-defined labels for cellery components.
public type Label "TEAM"|"OWNER"|"MAINTAINER";

public type DockerSource record{
    string Dockerfile;
    string tag;
    !...
};

public type ImageSource record{
    string image;
    !...
};

public type GitSource record{
    string gitRepo;
    string tag;
    !...
};

public type Definition record{
    string path;
    string method;
    !...
};

public type API record{
    string name?;
    string targetComponent;
    boolean global;
    TCPIngress|HTTPIngress ingress;
    !...
};

public type Egress record{
    string targetComponent?;
    string targetCell?;
    TCPIngress|HTTPIngress ingress?;
    string envVar?;
    Resiliency resiliency?;
    !...
};

public type Resiliency record{
    RetryConfig retryConfig?;
    FailoverConfig failoverConfig?;
    !...
};

public type RetryConfig record {
    int interval;
    int count;
    float backOffFactor;
    int maxWaitInterval;
    !...
};

public type FailoverConfig record {
    int timeOut;
    !...
};

public type Component record{
    string name;
    ImageSource source;
    int replicas = 1;
    map<string> env?;
    map<TCPIngress|HTTPIngress> ingresses;
    Egress[] egresses?;
    map<string> labels?;
    map<Env|Secret> parameters?;
    !...
};

public type TCPIngress object {
    public int port;
    public function __init(int port) {
        self.port = port;
    }
};

public type HTTPIngress object {
    public int port;
    public string basePath;
    public Definition[] definitions;

    public function __init(int port, string basePath, Definition[] definitions) {
        self.port = port;
        self.basePath = basePath;
        self.definitions = definitions;
    }
};

public type Env object {
    public string|int|boolean|float? value;

    public function __init(string|int|boolean|float? default = ()) {
        self.value = default;
    }

    public function setValue(string|int|boolean|float value) {
        self.value = value;
    }
};

public type Secret object {
    public string path;
    public string|int|boolean|float value;

    public function __init(string path, string|int|boolean|float value) {
        self.path = path;
        self.value = value;
    }

    public function __init() {
        self.path = "";
        self.value = "";
    }

    public function setValue(string|int|boolean|float value) {
        self.value = value;
    }
};

public type CellStub object {
    public string name;
    map<TCPIngress|HTTPIngress> ingresses = {};
    map<string> context = {};

    public function __init(string name) {
        self.name = name;
        self.ingresses = {};
        self.context = {};
    }

    public function addIngress(string context) {
        self.context = { name: context };
    }

    public function getIngress(string ingressName) returns string? {
        return self.context[ingressName];
    }
};

public type CellImage object {
    public string name;
    public Component[] components = [];
    public API?[] apis = [];
    public Egress?[] egresses = [];

    public function addComponent(Component component) {
        self.components[self.components.length()] = component;
    }

    public function exposeAPIsFrom(Component component) {
        foreach var (name, ingressTemp) in component.ingresses {
            self.apis[self.apis.length()] = {
                targetComponent: component.name,
                ingress: ingressTemp,
                global: false
            };
        }
    }

    public function exposeAPIFrom(Component component, string ingressName) {
        TCPIngress|HTTPIngress? ingress = component.ingresses[ingressName];
        if (ingress is (TCPIngress|HTTPIngress)) {
            self.apis[self.apis.length()] = {
                targetComponent: component.name,
                ingress: ingress,
                global: false
            };
        } else {
            error err = error("Ingress " + ingressName + " not found in the component " + component.name + ".");
            panic err;
        }
    }

    public function exposeGlobalAPI(Component component) {
        foreach var (name, ingressTemp) in component.ingresses {
            self.apis[self.apis.length()] = {
                targetComponent: component.name,
                ingress: ingressTemp,
                global: true
            };
        }
    }

    public function __init(string name) {
        self.name = name;
    }
};

# Build the cell aritifacts
#
# + cellImage - The cell image definition
# + return - true/false
public extern function createImage(CellImage cellImage) returns (boolean|error);

public function getHost(CellImage cellImage, Component component) returns (string) {
    return getValidName(cellImage.name) + "--" + getValidName(component.name) + "-service";
}

public function getBasePath(TCPIngress|HTTPIngress? httpIngress) returns (string) {
    if (httpIngress is HTTPIngress) {
        return httpIngress.basePath;
    }
    error err = error("Unable to extract basePath from ingress");
    panic err;
}

function getValidName(string name) returns string {
    return name.toLower().replace("_", "-").replace(".", "-");
}

public function setParameter(Env|Secret? param, string|int|boolean|float value) {
    if (param is (Env)) {
        param.value = value;
    } else if (param is Secret) {
        param.value = value;
    } else {
        error err = error("Parameter not declared in the component.");
        panic err;
    }
}
