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

isolated table<DeviceUserProfileData> key(id) profileTable = table [
    {id: 1, name: "Alice", age: 25},
    {id: 2, name: "Bob", age: 30},
    {id: 3, name: "Charlie", age: 35},
    {id: 4, name: "David", age: 40}
];

isolated table<RatingData> key(id) ratingTable = table [
    {id: 1, title: "Good", stars: 4, description: "Good product", authorId: 1},
    {id: 2, title: "Bad", stars: 2, description: "Bad product", authorId: 2},
    {id: 3, title: "Excellent", stars: 5, description: "Excellent product", authorId: 3},
    {id: 4, title: "Poor", stars: 1, description: "Poor product", authorId: 4}
];
