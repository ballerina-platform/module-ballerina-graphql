// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

final readonly & StarInfo[] stars = [
    {name: "Absolutno*", constellation: "Lynx", designation: "XO-5"},
    {name: "Acamar", constellation: "Eridanus", designation: "θ1 Eridani A"},
    {name: "Achernar", constellation: "Eridanus", designation: "α Eridani A"}
];

final readonly & Planet[] planets = [
    {id: 1, name: "Mercury", mass: 0.383, numberOfMoons: 0},
    {id: 2, name: "Venus", mass: 0.949, numberOfMoons: 0},
    {id: 3, name: "Earth", mass: 1, numberOfMoons: 1, moon: {name: "moon"}}
];
