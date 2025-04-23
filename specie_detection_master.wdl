version 1.0

import "specie_detection.wdl" as Sp

workflow SpecieDetection {
    input {
        String basespace_collection_id 
        String api_server
        String access_token
        String? sample_prefix

    }

    call GetReadsList {
        input:
            basespace_collection_id = basespace_collection_id,
            access_token = access_token,
            api_server = api_server,
            sample_prefix = sample_prefix

    }

    scatter(sample_name in GetReadsList.samples_name) {
        call Sp.Specie_Detect {
            input:
                sample_name = sample_name,
                basespace_collection_id = basespace_collection_id,
                api_server = api_server,
                access_token = access_token
        }

      
    }

    call MergeReports {
        input:
            species_detected_list = Specie_Detect.specie_detected
    }

    output {
        File reads_list = GetReadsList.reads_list
        Array[String] samples_name = GetReadsList.samples_name
        File species_detected_report = MergeReports.species_detected_report
    
    }
}

task GetReadsList {
    input {  
        String basespace_collection_id
        String api_server 
        String access_token
        String? sample_prefix
        String docker = "us-docker.pkg.dev/general-theiagen/theiagen/basespace_cli:1.2.1"

    }

    command <<<       
        bs project content --name ~{basespace_collection_id} \
            --api-server=~{api_server} \
            --access-token=~{access_token} \
            --retry > list_fetched.txt

        if [ -z "~{sample_prefix}" ]; then
            grep -o "[A-Z0-9_]*\.fastq\.gz" list_fetched.txt > reads_list.txt
        else
            grep -o "~{sample_prefix}[A-Z0-9_]*\.fastq\.gz" list_fetched.txt > reads_list.txt
        fi

        grep -o "[A-Z0-9_]*_R1_[0-9]*\.fastq\.gz" reads_list.txt | cut -d '_' -f 1 > sample_names.txt
    
    >>>

    output {
        File reads_list = "reads_list.txt"
        Array[String] samples_name = read_lines("sample_names.txt")
    }

    runtime {
        docker: docker
        preemptible: 1
  }
}

task MergeReports {
    input {
        Array[String] species_detected_list
    }

    command <<<
        echo "~{sep='\n' species_detected_list}" > species_detected_report.txt
    >>>

    output {
        File species_detected_report = "species_detected_report.txt"
    }

    runtime {
        docker: "ubuntu:20.04"

    }
}


