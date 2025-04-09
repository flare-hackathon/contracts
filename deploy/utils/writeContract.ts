import * as fs from 'fs'

export const writeToFile = (filePath: string, newData: any) => {
    fs.writeFileSync(filePath,
        JSON.stringify(newData, null, 2))
}